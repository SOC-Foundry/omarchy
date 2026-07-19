#!/usr/bin/env bash
# CHG-004 (83te / kt83teCos variant): shrink LUKS+btrfs OS, create LUKS+XFS /data
#
# Layout for this laptop (smaller drive than p3oos):
#   p1  vfat   2 GiB     /boot
#   p2  LUKS   200 GiB   btrfs OS  (filesystem target 185G)
#   p3  LUKS   remainder XFS /data
#
# Run as root from a live Omarchy session. Interactive LUKS passphrase required.
# Prerequisites: xfsprogs, parted, cryptsetup, btrfs-progs
set -euo pipefail

DISK=/dev/nvme0n1
P2=${DISK}p2
P3=${DISK}p3
MAPPER_ROOT=root
MAPPER_DATA=data

# Filesystem size inside the mapper (leave slack for LUKS header + safety margin)
BTRFS_TARGET=185G
# Partition end for p2 in GiB from start of disk (p1 ends at 2 GiB → p2 is 200 GiB)
P2_END_GIB=202
P3_START_GIB=202

# LUKS payload size after shrink (512-byte sectors). Slightly larger than btrfs.
# 190 GiB payload → leaves ~10 GiB slack inside the 200 GiB partition.
LUKS_PAYLOAD_GIB=190
LUKS_PAYLOAD_SECTORS=$((LUKS_PAYLOAD_GIB * 1024 * 1024 * 1024 / 512))

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ $(id -u) -eq 0 ]] || die "run as root (sudo bash $0)"

log "Preflight checks"
[[ -b $DISK ]] || die "missing $DISK"
[[ -b $P2 ]] || die "missing $P2"
[[ ! -b $P3 ]] || die "$P3 already exists — aborting to avoid data loss"
[[ -e /dev/mapper/$MAPPER_ROOT ]] || die "mapper $MAPPER_ROOT not open"
mountpoint -q / || die "/ is not a mountpoint"
findmnt -no FSTYPE / | grep -qx btrfs || die "/ is not btrfs"

if ! command -v mkfs.xfs >/dev/null 2>&1; then
  log "Installing xfsprogs"
  pacman -S --noconfirm xfsprogs
fi

USED_GIB=$(btrfs filesystem usage -b / | awk '/Used:/ {print int($2/1024/1024/1024); exit}')
log "btrfs used ≈ ${USED_GIB} GiB (must be well under ${BTRFS_TARGET})"
if (( USED_GIB > 160 )); then
  die "btrfs used (${USED_GIB}G) too close to target ${BTRFS_TARGET}; free space or raise target"
fi

log "Current layout"
lsblk -f "$DISK" || true
btrfs filesystem resize max / >/dev/null 2>&1 || true
df -hT /

log "Step 1/5: shrink btrfs on / to ${BTRFS_TARGET}"
btrfs filesystem resize "$BTRFS_TARGET" /
df -hT /
btrfs filesystem show /

log "Step 2/5: shrink LUKS mapper '${MAPPER_ROOT}' payload to ${LUKS_PAYLOAD_GIB} GiB (${LUKS_PAYLOAD_SECTORS} sectors)"
cryptsetup resize "$MAPPER_ROOT" --size "$LUKS_PAYLOAD_SECTORS"
cryptsetup status "$MAPPER_ROOT"

log "Step 3/5: shrink GPT partition 2 to end at ${P2_END_GIB} GiB"
parted -s "$DISK" unit GiB print
# resizepart end is inclusive end of partition in the unit used
parted -s "$DISK" -- resizepart 2 "${P2_END_GIB}GiB"
parted -s "$DISK" unit GiB print
partprobe "$DISK" || true
sleep 1
[[ -b $P2 ]] || die "p2 vanished after resize"

log "Step 4/5: create partition 3 from ${P3_START_GIB} GiB to 100%"
parted -s "$DISK" -- mkpart primary "${P3_START_GIB}GiB" 100%
partprobe "$DISK" || true
sleep 1
# Wait for udev
udevadm settle || true
for i in {1..20}; do
  [[ -b $P3 ]] && break
  sleep 0.5
done
[[ -b $P3 ]] || die "p3 not present after mkpart"
parted -s "$DISK" unit GiB print
lsblk -f "$DISK"

log "Step 5/5: LUKS-format p3 (USE THE SAME PASSPHRASE AS ROOT for single unlock prompt)"
wipefs -a "$P3" || true
cryptsetup luksFormat --type luks2 "$P3"
cryptsetup open "$P3" "$MAPPER_DATA"

log "Format XFS on /dev/mapper/${MAPPER_DATA}"
mkfs.xfs -f -L data "/dev/mapper/${MAPPER_DATA}"

log "Partition phase complete"
lsblk -f "$DISK"
cryptsetup status "$MAPPER_DATA" || true
xfs_info "/dev/mapper/${MAPPER_DATA}" || true

cat <<EOF

Next:
  sudo bash $(dirname "$0")/chg004-postboot.sh

EOF
