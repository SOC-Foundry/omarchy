#!/usr/bin/env bash
# CHG-004 post-partition: crypttab, fstab, mount /data, migrate Projects, symlink

set -euo pipefail

LUKS_DATA_NAME=data
P3_PART=/dev/nvme0n1p3
DATA_MOUNT=/data
PROJECTS_SRC=/home/kthompson/Development/Projects
PROJECTS_DST=$DATA_MOUNT/Development/Projects

log() { printf '\n[CHG-004] %s\n' "$*"; }
die() { printf '\n[CHG-004] ERROR: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo bash $0"
[[ -b $P3_PART ]] || die "$P3_PART missing — run chg004-partition.sh first."

P3_LUKS_UUID=$(cryptsetup luksUUID "$P3_PART")

log "Configure /etc/crypttab"
grep -q "^${LUKS_DATA_NAME} " /etc/crypttab 2>/dev/null || \
  echo "${LUKS_DATA_NAME} UUID=${P3_LUKS_UUID} none luks" >> /etc/crypttab

log "Open LUKS data volume and format check"
cryptsetup open "$P3_PART" "$LUKS_DATA_NAME" || true
[[ -b /dev/mapper/$LUKS_DATA_NAME ]] || die "Failed to open $LUKS_DATA_NAME"

mkdir -p "$DATA_MOUNT"
if ! mountpoint -q "$DATA_MOUNT"; then
  mount "/dev/mapper/$LUKS_DATA_NAME" "$DATA_MOUNT"
fi

XFS_UUID=$(blkid -s UUID -o value "/dev/mapper/$LUKS_DATA_NAME")

log "Configure /etc/fstab"
grep -q "$DATA_MOUNT" /etc/fstab || \
  echo "UUID=${XFS_UUID} ${DATA_MOUNT} xfs defaults,noatime 0 0" >> /etc/fstab

log "Regenerate initramfs (unlock /data at boot)"
if [[ -f /etc/mkinitcpio.conf.d/omarchy_hooks.conf ]]; then
  mkinitcpio -P
fi

mkdir -p "$(dirname "$PROJECTS_DST")"
chown kthompson:kthompson "$(dirname "$PROJECTS_DST")"

if [[ ! -d $PROJECTS_DST ]] || [[ -z "$(ls -A "$PROJECTS_DST" 2>/dev/null)" ]]; then
  log "Migrating Projects to XFS (this may take a while)..."
  rsync -aHAX --info=progress2 "$PROJECTS_SRC/" "$PROJECTS_DST/"
  chown -R kthompson:kthompson "$PROJECTS_DST"
fi

if [[ ! -L $PROJECTS_SRC ]]; then
  log "Symlinking $PROJECTS_SRC -> $PROJECTS_DST"
  mv "$PROJECTS_SRC" "${PROJECTS_SRC}.bak.chg004"
  sudo -u kthompson ln -s "$PROJECTS_DST" "$PROJECTS_SRC"
fi

log "Done. Verify:"
lsblk -f /dev/nvme0n1
mount | grep -E 'mapper/root|/data'
sudo -u kthompson ls -la /home/kthompson/Development/Projects
df -hT "$DATA_MOUNT"