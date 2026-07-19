#!/usr/bin/env bash
# Resume CHG-004 after btrfs (185G) + LUKS payload (190G) already shrunk.
# Remaining: GPT resize p2, create p3, LUKS+XFS, postboot.
# Expects CHG004_KEYFILE env = path to LUKS passphrase file.
set -euo pipefail

DISK=/dev/nvme0n1
P2=${DISK}p2
P3=${DISK}p3
MAPPER_ROOT=root
MAPPER_DATA=data

P2_END_GIB=202
P3_START_GIB=202
LUKS_PAYLOAD_GIB=190
LUKS_PAYLOAD_SECTORS=$((LUKS_PAYLOAD_GIB * 1024 * 1024 * 1024 / 512))

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ $(id -u) -eq 0 ]] || die "run as root: sudo bash $0"

KEYFILE="${CHG004_KEYFILE:-}"
[[ -n "$KEYFILE" && -f "$KEYFILE" && -s "$KEYFILE" ]] || die "CHG004_KEYFILE missing/empty"

log "State check"
df -hT /
lsblk -b -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DISK"
cryptsetup status "$MAPPER_ROOT" || true

# Ensure LUKS payload is 190G (idempotent)
CURRENT_SECTORS=$(blockdev --getsz /dev/mapper/$MAPPER_ROOT)
log "Current mapper sectors: $CURRENT_SECTORS (target $LUKS_PAYLOAD_SECTORS)"
if (( CURRENT_SECTORS > LUKS_PAYLOAD_SECTORS )); then
  log "Shrinking LUKS mapper to ${LUKS_PAYLOAD_GIB} GiB"
  cryptsetup resize "$MAPPER_ROOT" --size "$LUKS_PAYLOAD_SECTORS" --key-file "$KEYFILE"
elif (( CURRENT_SECTORS < LUKS_PAYLOAD_SECTORS )); then
  die "mapper smaller than expected ($CURRENT_SECTORS < $LUKS_PAYLOAD_SECTORS) — stop and inspect"
else
  log "LUKS mapper already at target size"
fi
cryptsetup status "$MAPPER_ROOT"

# Partition 2 size check
P2_BYTES=$(blockdev --getsize64 "$P2")
TARGET_P2_BYTES=$((200 * 1024 * 1024 * 1024))  # 200 GiB
log "p2 bytes=$P2_BYTES target≈$TARGET_P2_BYTES"

if (( P2_BYTES > TARGET_P2_BYTES + 1024*1024*1024 )); then
  log "Step 3/5: shrink GPT partition 2 to end at ${P2_END_GIB} GiB (needs Yes confirm)"
  parted -s "$DISK" unit GiB print
  # parted requires interactive Yes for shrink even with -s in some versions
  printf 'Yes\n' | parted ---pretend-input-tty "$DISK" unit GiB resizepart 2 "${P2_END_GIB}GiB"
  partprobe "$DISK" || true
  sleep 1
  udevadm settle || true
  parted -s "$DISK" unit GiB print
else
  log "p2 already near 200 GiB — skip resizepart"
fi

P2_BYTES=$(blockdev --getsize64 "$P2")
log "p2 bytes after: $P2_BYTES"
if (( P2_BYTES < 190 * 1024 * 1024 * 1024 )); then
  die "p2 too small after resize ($P2_BYTES) — abort before creating p3"
fi

if [[ ! -b $P3 ]]; then
  log "Step 4/5: create partition 3 from ${P3_START_GIB} GiB to 100%"
  parted -s "$DISK" -- mkpart primary "${P3_START_GIB}GiB" 100%
  partprobe "$DISK" || true
  sleep 1
  udevadm settle || true
  for i in {1..30}; do
    [[ -b $P3 ]] && break
    sleep 0.5
  done
  [[ -b $P3 ]] || die "p3 not present after mkpart"
  parted -s "$DISK" name 3 data || true
else
  log "p3 already exists"
fi

parted -s "$DISK" unit GiB print
lsblk -f "$DISK"

# Format p3 if not already LUKS
if blkid -o value -s TYPE "$P3" 2>/dev/null | grep -q crypto_LUKS; then
  log "p3 already LUKS"
  if [[ ! -e /dev/mapper/$MAPPER_DATA ]]; then
    cryptsetup open --key-file "$KEYFILE" "$P3" "$MAPPER_DATA"
  fi
else
  log "Step 5/5: LUKS-format p3 + open + XFS"
  wipefs -a "$P3" || true
  cryptsetup luksFormat --type luks2 --batch-mode --key-file "$KEYFILE" "$P3"
  cryptsetup open --key-file "$KEYFILE" "$P3" "$MAPPER_DATA"
fi

if [[ ! -e /dev/mapper/$MAPPER_DATA ]]; then
  die "mapper $MAPPER_DATA not open"
fi

FSTYPE=$(blkid -o value -s TYPE "/dev/mapper/$MAPPER_DATA" || true)
if [[ "$FSTYPE" != xfs ]]; then
  if ! command -v mkfs.xfs >/dev/null 2>&1; then
    pacman -S --noconfirm xfsprogs
  fi
  mkfs.xfs -f -L data "/dev/mapper/${MAPPER_DATA}"
else
  log "XFS already on data mapper"
fi

log "Partition phase complete"
lsblk -f "$DISK"
cryptsetup status "$MAPPER_DATA" || true
blkid "$P3" "/dev/mapper/$MAPPER_DATA" || true

POST="$(dirname "$0")/chg004-postboot.sh"
log "Running postboot: $POST"
bash "$POST"

log "All done. Reboot when ready: reboot"
