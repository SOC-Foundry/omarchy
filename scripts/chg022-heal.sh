#!/usr/bin/env bash
# CHG-022 heal loop. One root shell. Does not reboot.
# Asks for the boot passphrase up to three times. The partition is not
# changed unless the open LUKS mapping actually shrinks to 179 GiB.
set -u

LOG=/home/kthompson/chg022-heal.log
DEBUG=/home/kthompson/chg022-heal-debug.txt
LUKS_DEV=/dev/nvme0n1p2
MAPPER=root
TARGET_BYTES=$((179 * 1024 * 1024 * 1024))
MAX_TRIES=3

say() { printf '%s\n' "$*" | tee -a "$LOG" >/dev/tty; }
mark() { wc -c < "$DEBUG" | tr -d ' '; }
slice_since() { tail -c +"$(( $1 + 1 ))" "$DEBUG"; }

[[ $(id -u) -eq 0 ]] || { echo "run as root: sudo bash $0" >&2; exit 1; }
[[ -t 0 ]] || { echo "need a terminal" >&2; exit 1; }

{
  echo
  echo "======== heal run $(date -Is) ========"
} >>"$LOG"
: >>"$DEBUG"

say "Filesystem is 174 GiB. This step only checks the boot passphrase, then shrinks the LUKS mapping."
say "The partition is not touched unless that shrink succeeds."

PASS_OK=0
HEAL_CLASS=unclassified
for attempt in $(seq 1 "$MAX_TRIES"); do
  say ""
  say "======== BOOT PASSPHRASE  attempt ${attempt} of ${MAX_TRIES} ========"
  say "Type the passphrase from the disk-unlock screen at startup."
  say "Do not type the login password you used for sudo."
  say "cryptsetup will ask: Enter passphrase for ${LUKS_DEV}"
  say "A wrong secret says: No key available with this passphrase."
  say "Wait several seconds after Enter. The check uses about 1 GiB of memory."
  before=$(mark)
  set +e
  cryptsetup --debug open --test-passphrase "$LUKS_DEV" </dev/tty >>"$DEBUG" 2>&1
  rc=$?
  set -e
  piece=$(slice_since "$before")
  printf 'attempt=%s module=test-passphrase rc=%s\n' "$attempt" "$rc" | tee -a "$LOG" >/dev/tty
  printf '%s\n' "$piece" >>"$LOG"
  if [[ "$rc" -eq 0 ]]; then
    PASS_OK=1
    HEAL_CLASS=passphrase-ok
    say "Boot passphrase accepted by a keyslot."
    break
  fi
  if printf '%s\n' "$piece" | grep -q 'No key available with this passphrase'; then
    HEAL_CLASS=bad-passphrase
    say "Rejected. Every keyslot refused that secret. It is not the boot passphrase."
    continue
  fi
  HEAL_CLASS=test-unclassified
  say "cryptsetup failed for a reason other than a bad passphrase. Stopping. Log: $LOG"
  break
done

if [[ "$PASS_OK" -ne 1 ]]; then
  say "HEAL_CLASS=$HEAL_CLASS"
  say "Partition was not changed. No further window will be opened by this script."
  exit 1
fi

say ""
say "======== SAME BOOT PASSPHRASE, SHRINK ========"
say "Type that same boot passphrase again. This shrinks the mapping to 179 GiB."
say "Wait several seconds after Enter."
before=$(mark)
set +e
cryptsetup --debug resize "$MAPPER" --device-size 179G </dev/tty >>"$DEBUG" 2>&1
rc=$?
set -e
piece=$(slice_since "$before")
printf 'module=resize rc=%s\n' "$rc" | tee -a "$LOG" >/dev/tty
printf '%s\n' "$piece" >>"$LOG"

NOW=$(blockdev --getsize64 "/dev/mapper/$MAPPER" 2>/dev/null || echo 0)
say "mapper bytes after resize: $NOW (target $TARGET_BYTES)"

if [[ "$rc" -ne 0 || "$NOW" -gt "$TARGET_BYTES" ]]; then
  if printf '%s\n' "$piece" | grep -Eqi 'busy|suspend|ioctl|permission denied|Operation not permitted'; then
    HEAL_CLASS=resize-blocked
  elif printf '%s\n' "$piece" | grep -q 'No key available with this passphrase'; then
    HEAL_CLASS=resize-bad-passphrase
  else
    HEAL_CLASS=resize-unclassified
  fi
  say "HEAL_CLASS=$HEAL_CLASS"
  say "LUKS was not shrunk. The partition was not changed."
  exit 1
fi

say "HEAL_CLASS=resize-ok"
say "Mapping is 179 GiB. Continuing to the data partition in this same root shell."
export CHG022_HEAL_AFTER_LUKS=1 CHG022_RIP=1
exec bash /home/kthompson/Development/Projects/socfoundry/omarchy/scripts/chg022-data-volume.sh
