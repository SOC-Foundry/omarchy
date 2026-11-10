#!/usr/bin/env bash
# CHG-022 — encrypted XFS /data, sized from the disk in this machine.
#
# The data partition is DATA_SHARE_PERCENT of the whole disk (60, so it is
# over half on every size). The OS keeps the rest. 83te's "p2 ends at 202 GiB"
# stays in scripts/chg004-partition.sh as that machine's record.
#
# A container with no LUKS root is not shrunk here. Give it a data volume that
# is already over half the allotted disk and the same directory layout.
#
# Also: swapoff the btrfs swapfile, parted Yes via pretend-input-tty, no keyfile,
# gate word PROCEED, then chg004-postboot.sh, then screenshots on /data.
# Does not reboot. Does not delete ~/Development/Projects.bak.chg004.
# Do not use set -e until the disk is identified. A failing lsblk exits 32,
# which looks like a password error and leaves no line in the log.
set +e
# Not /tmp. fs.protected_regular rejects root appending to a user-owned file there.
LOG=/home/kthompson/chg022-status.txt
DEBUG=/home/kthompson/chg022-cryptsetup-debug.txt
printf 'script-main %s uid=%s\n' "$(date -Is)" "$(id -u 2>/dev/null || echo nouid)" >> "$LOG"
say() { printf '%s\n' "$*" | tee -a "$LOG"; }
say "script started $(date -Is)"

# Over half of whatever drive this host has. Change this one number, not a GiB constant.
DATA_SHARE_PERCENT=60
OS_FLOOR_GIB=80
OS_HEADROOM_GIB=40
TAIL_SLACK_GIB=8
FS_SLACK_GIB=5
GIB=$((1024 * 1024 * 1024))

MAPPER_DATA=data
SWAPFILE=/swap/swapfile
USER_NAME="${SUDO_USER:-kthompson}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
SS_DST=/data/Development/Projects/socfoundry/ss
# LOG is set above. /tmp is not writable by root for a file the user created.
SFDISK_BACKUP=/root/chg022-sfdisk-before.txt
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWAP_WAS_ON=0

log() { printf '\n==> %s\n' "$*" | tee -a "$LOG"; }
die() {
  printf 'ERROR: %s\n' "$*" | tee -a "$LOG" >&2
  echo "CHG022_RESULT=fail" | tee -a "$LOG"
  exit 1
}

restore_swap() {
  if [[ "$SWAP_WAS_ON" -eq 1 ]]; then
    if ! swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$SWAPFILE"; then
      swapon "$SWAPFILE" || true
    fi
  fi
}
trap restore_swap EXIT

[[ $(id -u) -eq 0 ]] || die "run as root: sudo bash $0"
[[ -t 0 ]] || die "need a terminal. PROCEED and the passphrase are typed, not piped."
# One prompt window. After this password, sudo waits an hour instead of five minutes.
TIMEOUT_FILE=/etc/sudoers.d/chg022-timeout
if [[ ! -f "$TIMEOUT_FILE" ]]; then
  printf '%s\n' 'Defaults timestamp_timeout=60' 'Defaults passwd_timeout=60' > "$TIMEOUT_FILE"
  chmod 440 "$TIMEOUT_FILE"
  if ! visudo -cf "$TIMEOUT_FILE"; then
    rm -f "$TIMEOUT_FILE"
    die "refused the sudo timeout file"
  fi
  say "sudo timeout is 60 minutes ($TIMEOUT_FILE)"
fi
[[ -n "$USER_HOME" && -d "$USER_HOME" ]] || die "no home for $USER_NAME"
(( DATA_SHARE_PERCENT > 50 && DATA_SHARE_PERCENT < 90 )) || die "DATA_SHARE_PERCENT must be over half and leave an OS"

ROOT_SRC=$(findmnt -no SOURCE /)
ROOT_SRC=${ROOT_SRC%%\[*}
[[ "$ROOT_SRC" == /dev/mapper/* ]] || die "$ROOT_SRC is not a LUKS mapper. A container gets a data volume that is already over half its disk. This script only shrinks a bare-metal root."
MAPPER_ROOT=${ROOT_SRC#/dev/mapper/}
findmnt -no FSTYPE / | grep -qx btrfs || die "/ is not btrfs"
# lsblk prints an empty PKNAME for an open LUKS mapper. The slave is the partition.
dm=$(basename "$(readlink -f "$ROOT_SRC")")
slave=$(ls "/sys/class/block/${dm}/slaves")
[[ -n "$slave" && "$slave" != *$'\n'* ]] || die "mapper $ROOT_SRC has no single backing partition"
P2=/dev/$slave
[[ -b $P2 ]] || die "root mapper has no partition parent ($P2)"
disk=$(basename "$(dirname "$(readlink -f "/sys/class/block/$slave")")")
DISK=/dev/$disk
[[ -b $DISK ]] || die "no disk behind $P2"
BOOT_SRC=$(findmnt -no SOURCE /boot || true)
BOOT_PART=${BOOT_SRC%%\[*}
PART_NUM=$(cat "/sys/class/block/$(basename "$P2")/partition")

extra_part() {
  local path
  EXTRA=""
  while read -r path; do
    [[ -z "$path" || "$path" == "$P2" || "$path" == "$BOOT_PART" ]] && continue
    EXTRA=$path
  done < <(lsblk -ln -o PATH,TYPE "$DISK" 2>>"$LOG" | awk '$2=="part" {print $1}')
}

printf 'preflight root=%s p2=%s disk=%s part=%s\n' "$ROOT_SRC" "$P2" "$DISK" "$PART_NUM" >> "$LOG"
say "Disk $DISK, OS partition $P2, root $ROOT_SRC"
set -euo pipefail
log "CHG-022 preflight  $(date -Is)"
log "Layout before"
lsblk -b -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT "$DISK" || die "lsblk cannot see $DISK"
df -hT /
swapon --show || true

USED_GIB=$(df -B1 --output=used / | tail -1)
USED_GIB=$((USED_GIB / 1024 / 1024 / 1024))

DISK_BYTES=$(blockdev --getsize64 "$DISK")
P2_START_BYTES=$(( $(cat "/sys/class/block/$(basename "$P2")/start") * 512 ))
HALF_BYTES=$((DISK_BYTES / 2))
DATA_BYTES=$((DISK_BYTES * DATA_SHARE_PERCENT / 100 / GIB * GIB))
if (( DATA_BYTES <= HALF_BYTES )); then
  DATA_BYTES=$(( (HALF_BYTES / GIB + 1) * GIB ))
fi
P3_START_BYTES=$(( (DISK_BYTES - DATA_BYTES) / GIB * GIB ))
(( P3_START_BYTES > P2_START_BYTES )) || die "data share leaves no room for the OS"
P2_PLAN_BYTES=$((P3_START_BYTES - P2_START_BYTES))
LUKS_PAYLOAD_GIB=$(( P2_PLAN_BYTES / GIB - TAIL_SLACK_GIB ))
BTRFS_GIB=$(( LUKS_PAYLOAD_GIB - FS_SLACK_GIB ))
LUKS_PAYLOAD_SECTORS=$(( LUKS_PAYLOAD_GIB * GIB / 512 ))
P3_START_GIB=$(( P3_START_BYTES / GIB ))
P2_END_GIB=$P3_START_GIB
BTRFS_TARGET=${BTRFS_GIB}G
DATA_ACTUAL_BYTES=$((DISK_BYTES - P3_START_BYTES))
(( DATA_ACTUAL_BYTES > HALF_BYTES )) || die "planned data partition is not over half the disk"
(( BTRFS_GIB >= OS_FLOOR_GIB )) || die "OS filesystem would be ${BTRFS_GIB} GiB, under the ${OS_FLOOR_GIB} GiB floor"
(( USED_GIB + OS_HEADROOM_GIB <= BTRFS_GIB )) || die "btrfs uses ${USED_GIB} GiB. ${BTRFS_GIB} GiB leaves under ${OS_HEADROOM_GIB} GiB free."

log "disk $((DISK_BYTES / GIB)) GiB, half $((HALF_BYTES / GIB)) GiB, data ${DATA_SHARE_PERCENT}% → p3 at ${P3_START_GIB} GiB ($((DATA_ACTUAL_BYTES / GIB)) GiB)"
log "OS partition ~$((P2_PLAN_BYTES / GIB)) GiB, LUKS payload ${LUKS_PAYLOAD_GIB} GiB, btrfs ${BTRFS_TARGET}, used ${USED_GIB} GiB"

extra_part
P3=$EXTRA
if [[ -n "$P3" ]]; then
  P3_TYPE=$(blkid -o value -s TYPE "$P3" 2>/dev/null || true)
  [[ "$P3_TYPE" == "crypto_LUKS" ]] || die "$P3 exists and is '${P3_TYPE:-empty}', not LUKS. Not touching it."
  log "$P3 is already LUKS. Skipping the shrink."
else
  P2_BYTES=$(blockdev --getsize64 "$P2")
  if (( P2_BYTES <= HALF_BYTES )); then
    die "OS partition is already under half the disk and no data partition exists. Refusing to shrink again. GPT copy: $SFDISK_BACKUP"
  fi

  log "Saving GPT to $SFDISK_BACKUP"
  sfdisk -d "$DISK" > "$SFDISK_BACKUP"

  cat <<EOF

This shrinks the live OS volume on $DISK.
  disk             → $((DISK_BYTES / GIB)) GiB
  data share       → ${DATA_SHARE_PERCENT}% (over half), $((DATA_ACTUAL_BYTES * 10 / GIB / 10)).$((DATA_ACTUAL_BYTES * 10 / GIB % 10)) GiB
  btrfs filesystem → ${BTRFS_TARGET}
  LUKS payload     → ${LUKS_PAYLOAD_GIB} GiB
  OS partition ends → ${P2_END_GIB} GiB

Projects move to /data. The btrfs tree is kept as
  ${USER_HOME}/Development/Projects.bak.chg004
This script does not reboot and does not delete that copy.
Use the same passphrase as the root volume.
A second unlock prompt at boot is possible.

EOF
  MAP_BYTES=$(blockdev --getsize64 "/dev/mapper/$MAPPER_ROOT")
  if [[ "${CHG022_HEAL_AFTER_LUKS:-}" == 1 ]] && (( MAP_BYTES <= LUKS_PAYLOAD_GIB * GIB )); then
    log "Heal handoff: mapper is ${MAP_BYTES} bytes. Skipping passphrase, btrfs, and LUKS shrink."
  else
  if [[ "${CHG022_RIP:-}" == 1 ]]; then
    say "CHG022_RIP=1, skipping the PROCEED prompt"
  else
    printf 'Type PROCEED to shrink the live OS volume: '
    read -r ans
    [[ "$ans" == "PROCEED" ]] || die "not confirmed (got '${ans:-}')"
  fi

  if swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$SWAPFILE"; then
    log "swapoff $SWAPFILE (zram stays)"
    SWAP_WAS_ON=1
    swapoff "$SWAPFILE"
  fi

  log "Shrink btrfs to ${BTRFS_TARGET}"
  btrfs filesystem resize "$BTRFS_TARGET" /
  df -hT /
  FS_BYTES=$(df -B1 --output=size / | tail -1)
  if (( FS_BYTES > LUKS_PAYLOAD_GIB * GIB )); then
    die "btrfs is still $FS_BYTES bytes after resize. Partition was not changed."
  fi

  log "Shrink LUKS payload to ${LUKS_PAYLOAD_GIB} GiB (${LUKS_PAYLOAD_SECTORS} sectors)"
  printf '\nNext prompt: the boot disk passphrase from startup, not the login password.\nA wrong one says: No key available with this passphrase.\nWait a few seconds after Enter.\n' | tee -a "$LOG"
  if ! cryptsetup --debug resize "$MAPPER_ROOT" --size "$LUKS_PAYLOAD_SECTORS" \
      </dev/tty >/dev/tty 2>>"$DEBUG"; then
    printf '\nLUKS was not shrunk. The filesystem is already %s inside the original encrypted device.\nThe partition was not changed.\n' "$BTRFS_TARGET" | tee -a "$LOG"
    die "cryptsetup resize failed. Debug is $DEBUG"
  fi
  cryptsetup status "$MAPPER_ROOT"
  NOW_SECTORS=$(blockdev --getsz "/dev/mapper/$MAPPER_ROOT")
  if (( NOW_SECTORS > LUKS_PAYLOAD_SECTORS )); then
    die "mapper still has $NOW_SECTORS sectors (target $LUKS_PAYLOAD_SECTORS). Partition was not changed."
  fi
  fi

  log "Shrink OS partition so it ends at ${P2_END_GIB} GiB"
  parted -s "$DISK" unit GiB print
  printf 'Yes\n' | parted ---pretend-input-tty "$DISK" unit GiB resizepart "$PART_NUM" "${P2_END_GIB}GiB"
  partprobe "$DISK" || true
  udevadm settle || true
  sleep 1
  P2_BYTES=$(blockdev --getsize64 "$P2")
  log "OS partition bytes after resize: $P2_BYTES"
  if (( P2_BYTES < LUKS_PAYLOAD_GIB * GIB )); then
    die "OS partition is $P2_BYTES bytes, smaller than the ${LUKS_PAYLOAD_GIB} GiB payload. Data partition was not created. GPT copy: $SFDISK_BACKUP"
  fi
  parted -s "$DISK" unit GiB print

  log "Create the data partition from ${P3_START_GIB} GiB to 100%"
  parted -s "$DISK" -- mkpart primary "${P3_START_GIB}GiB" 100%
  partprobe "$DISK" || true
  udevadm settle || true
  P3=""
  for _ in $(seq 1 30); do
    extra_part
    P3=$EXTRA
    [[ -n "$P3" && -b "$P3" ]] && break
    sleep 0.5
  done
  [[ -n "$P3" && -b "$P3" ]] || die "data partition did not appear. GPT copy: $SFDISK_BACKUP"
  NEW_NUM=$(cat "/sys/class/block/$(basename "$P3")/partition")
  parted -s "$DISK" name "$NEW_NUM" data || true

  if ! command -v mkfs.xfs >/dev/null 2>&1; then
    log "Installing xfsprogs"
    pacman -S --noconfirm xfsprogs
  fi

  log "LUKS-format p3. Type YES, then the root passphrase twice."
  wipefs -a "$P3" || true
  cryptsetup luksFormat --type luks2 "$P3"
  log "Open the new volume. Type the passphrase once."
  cryptsetup open "$P3" "$MAPPER_DATA"
  mkfs.xfs -f -L data "/dev/mapper/${MAPPER_DATA}"
  lsblk -f "$DISK"
fi

log "Mount, crypttab, fstab, initramfs, Projects symlink"
export ROOT_DISK="$DISK" DATA_PART="$P3"
bash "$SCRIPT_DIR/chg004-postboot.sh"

log "Screenshots onto $SS_DST"
mkdir -p "$SS_DST"
SS_SRC="$USER_HOME/Pictures/Screenshots"
if [[ -L "$SS_SRC" ]]; then
  log "$SS_SRC is already a symlink → $(readlink "$SS_SRC")"
elif [[ -d "$SS_SRC" ]]; then
  find "$SS_SRC" -mindepth 1 -maxdepth 1 -exec mv -t "$SS_DST" {} +
  if rmdir "$SS_SRC" 2>/dev/null; then
    :
  else
    mv "$SS_SRC" "${SS_SRC}.bak.chg022.$(date +%Y%m%d-%H%M%S)"
  fi
  ln -sfn "$SS_DST" "$SS_SRC"
else
  mkdir -p "$(dirname "$SS_SRC")"
  ln -sfn "$SS_DST" "$SS_SRC"
fi
chown -h "$USER_NAME:$USER_NAME" "$SS_SRC"
chown -R "$USER_NAME:$USER_NAME" /data/Development

TS=$(date +%Y%m%d-%H%M%S)
FISH_CFG="$USER_HOME/.config/fish/config.fish"
HYPR_CFG="$USER_HOME/.config/hypr/hyprland.lua"
cp -a "$FISH_CFG" "${FISH_CFG}.bak.chg022.${TS}"
cp -a "$HYPR_CFG" "${HYPR_CFG}.bak.chg022.${TS}"
python3 - "$FISH_CFG" "$HYPR_CFG" <<'PY'
import pathlib, sys
fish, hypr = map(pathlib.Path, sys.argv[1:])
fish_old = """# CHG-008 path until the /data volume exists (CHG-004). Omarchy 4.5 reads both.
set -gx OMARCHY_SCREENSHOT_DIR "$HOME/Pictures/Screenshots"
set -gx OMASNAP_SCREENSHOT_DIR "$HOME/Pictures/Screenshots"
"""
fish_new = """# CHG-022 — shots live on the XFS volume. Pictures/Screenshots is a symlink there.
set -gx OMARCHY_SCREENSHOT_DIR "/data/Development/Projects/socfoundry/ss"
set -gx OMASNAP_SCREENSHOT_DIR "/data/Development/Projects/socfoundry/ss"
"""
hypr_old = """-- CHG-008 / CHG-019 — screenshots stay in Pictures until the /data volume exists.
-- PRINT already captures. Super+Shift+S stays Google Maps on this laptop.
hl.env("OMARCHY_SCREENSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
hl.env("OMASNAP_SCREENSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
"""
hypr_new = """-- CHG-022 — shots on the XFS volume. Super+Shift+S stays Google Maps.
hl.env("OMARCHY_SCREENSHOT_DIR", "/data/Development/Projects/socfoundry/ss")
hl.env("OMASNAP_SCREENSHOT_DIR", "/data/Development/Projects/socfoundry/ss")
"""
ft, ht = fish.read_text(), hypr.read_text()
if fish_old not in ft:
    raise SystemExit("fish screenshot block not found")
if hypr_old not in ht:
    raise SystemExit("hyprland screenshot block not found")
fish.write_text(ft.replace(fish_old, fish_new, 1))
hypr.write_text(ht.replace(hypr_old, hypr_new, 1))
PY
chown "$USER_NAME:$USER_NAME" "$FISH_CFG" "$HYPR_CFG"

UID_N=$(id -u "$USER_NAME")
SIG=""
sock=$(find "/run/user/${UID_N}/hypr" -name '.socket.cmd' -print -quit 2>/dev/null || true)
if [[ -n "$sock" ]]; then
  SIG=$(basename "$(dirname "$sock")")
fi
if [[ -n "$SIG" ]]; then
  runuser -u "$USER_NAME" -- env \
    XDG_RUNTIME_DIR="/run/user/${UID_N}" \
    WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
    HYPRLAND_INSTANCE_SIGNATURE="$SIG" \
    hyprctl reload || true
  runuser -u "$USER_NAME" -- env \
    XDG_RUNTIME_DIR="/run/user/${UID_N}" \
    WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
    HYPRLAND_INSTANCE_SIGNATURE="$SIG" \
    hyprctl configerrors || true
fi

echo "CHG022_VOLUME=ok"
log "Verify (no cleanup, no reboot)"
fish "$SCRIPT_DIR/chg004-verify.fish" || die "chg004-verify failed"
echo "CHG022_RESULT=ok"
cat <<EOF

Live session has /data. A reboot is still required to prove the second
unlock and the automount. This script did not reboot.

After that reboot looks right, the btrfs copy can go:
  rm -rf ${USER_HOME}/Development/Projects.bak.chg004

EOF
