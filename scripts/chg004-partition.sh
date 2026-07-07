#!/usr/bin/env bash
# CHG-004: Shrink nvme0n1p2 (LUKS+btrfs OS) to 350 GiB, create nvme0n1p3 (LUKS+XFS /data)
# Layout A: p2 ~350 GiB OS | p3 ~580 GiB data
#
# REQUIRES: root (sudo). Prefer running from Omarchy/Ventoy live ISO if live shrink fails.
# PRE-FLIGHT: ~/Projects.chg004.bak must exist (45G backup on btrfs).

set -euo pipefail

DISK=/dev/nvme0n1
P2_PART=${DISK}p2
P3_PART=${DISK}p3
LUKS_OS_NAME=root
LUKS_DATA_NAME=data
MOUNT_OS=/mnt/chg004-os
BTRFS_TARGET=330G
P2_END_GIB=352GiB
P3_START_GIB=352GiB
# 330 GiB btrfs + ~64 MiB LUKS2 margin → sector count for cryptsetup resize
LUKS_SECTORS=$((330 * 1024 * 1024 * 1024 / 512 + 131072))

log() { printf '\n[CHG-004] %s\n' "$*"; }
die() { printf '\n[CHG-004] ERROR: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo bash $0"

[[ -d /home/kthompson/Projects.chg004.bak ]] || die "Missing ~/Projects.chg004.bak — abort."

command -v mkfs.xfs >/dev/null || {
  log "Installing xfsprogs (required for XFS)..."
  pacman -S --noconfirm xfsprogs
}

log "Current layout:"
lsblk -f "$DISK"
parted "$DISK" print free

read -r -p "Type YES to shrink $P2_PART and create $P3_PART: " confirm
[[ $confirm == YES ]] || die "Aborted."

log "Step 1/6: Shrink btrfs filesystem to $BTRFS_TARGET"
btrfs filesystem resize "$BTRFS_TARGET" /

log "Step 2/6: Shrink LUKS container $LUKS_OS_NAME to $LUKS_SECTORS sectors"
cryptsetup resize --size "$LUKS_SECTORS" "$LUKS_OS_NAME"

log "Step 3/6: Shrink partition $P2_PART end to $P2_END_GIB"
parted ---pretend-input-tty "$DISK" resizepart 2 "$P2_END_GIB" <<< "Yes"
partprobe "$DISK"
sleep 2

log "Step 4/6: Create partition 3 ($P3_START_GIB to 100%)"
if ! parted "$DISK" print | grep -q '^ 3 '; then
  parted ---pretend-input-tty "$DISK" mkpart primary "$P3_START_GIB" 100% <<< "Yes"
  partprobe "$DISK"
  sleep 2
fi

[[ -b $P3_PART ]] || die "$P3_PART not found after mkpart"

log "Step 5/6: LUKS format + XFS on $P3_PART"
if ! cryptsetup isLuks "$P3_PART" 2>/dev/null; then
  log "Use the SAME passphrase as your existing root LUKS volume."
  cryptsetup luksFormat --type luks2 "$P3_PART"
fi

cryptsetup open "$P3_PART" "$LUKS_DATA_NAME"
mkfs.xfs -f -L data "/dev/mapper/$LUKS_DATA_NAME"
cryptsetup close "$LUKS_DATA_NAME"

log "Step 6/6: Record UUIDs"
P3_LUKS_UUID=$(cryptsetup luksUUID "$P3_PART")
P2_LUKS_UUID=$(cryptsetup luksUUID "$P2_PART")
printf '\n# Add to /etc/crypttab:\n'
printf '%s UUID=%s none luks\n' "$LUKS_DATA_NAME" "$P3_LUKS_UUID"
printf '\n# Add to /etc/fstab (after blkid for XFS UUID):\n'
printf '/dev/mapper/%s /data xfs defaults,noatime 0 0\n' "$LUKS_DATA_NAME"
printf '\nP2 LUKS UUID: %s\nP3 LUKS UUID: %s\n' "$P2_LUKS_UUID" "$P3_LUKS_UUID"

log "Partition work complete. Run: sudo bash scripts/chg004-postboot.sh"