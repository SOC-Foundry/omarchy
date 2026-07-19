#!/usr/bin/env bash
# Format p3 as LUKS+XFS, wire crypttab/fstab, migrate Projects.
# Requires CHG004_KEYFILE with root LUKS passphrase (same for data).
set -euo pipefail

DISK=/dev/nvme0n1
P3=${DISK}p3
MAPPER_DATA=data
USER_NAME="${SUDO_USER:-kthompson}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ $(id -u) -eq 0 ]] || die "run as root"
KEYFILE="${CHG004_KEYFILE:-}"
[[ -n "$KEYFILE" && -f "$KEYFILE" && -s "$KEYFILE" ]] || die "CHG004_KEYFILE missing"

[[ -b $P3 ]] || die "missing $P3 — partition step incomplete"
command -v mkfs.xfs >/dev/null || pacman -S --noconfirm xfsprogs

if [[ ! -e /dev/mapper/$MAPPER_DATA ]]; then
  if blkid -o value -s TYPE "$P3" 2>/dev/null | grep -q crypto_LUKS; then
    log "Opening existing LUKS on p3"
    cryptsetup open --key-file "$KEYFILE" "$P3" "$MAPPER_DATA"
  else
    log "LUKS-format p3 (batch) + open"
    wipefs -a "$P3" || true
    cryptsetup luksFormat --type luks2 --batch-mode --key-file "$KEYFILE" "$P3"
    cryptsetup open --key-file "$KEYFILE" "$P3" "$MAPPER_DATA"
  fi
fi

FSTYPE=$(blkid -o value -s TYPE "/dev/mapper/$MAPPER_DATA" || true)
if [[ "$FSTYPE" != xfs ]]; then
  log "mkfs.xfs on /dev/mapper/$MAPPER_DATA"
  mkfs.xfs -f -L data "/dev/mapper/$MAPPER_DATA"
fi

DATA_LUKS_UUID=$(cryptsetup luksUUID "$P3")
DATA_FS_UUID=$(blkid -o value -s UUID "/dev/mapper/$MAPPER_DATA")
log "data LUKS UUID=$DATA_LUKS_UUID"
log "data XFS  UUID=$DATA_FS_UUID"

if ! grep -qE '^[[:space:]]*data[[:space:]]' /etc/crypttab 2>/dev/null; then
  cp -a /etc/crypttab "/etc/crypttab.bak.$(date +%Y%m%d-%H%M%S)"
  printf 'data  UUID=%s  none  luks\n' "$DATA_LUKS_UUID" >> /etc/crypttab
  log "crypttab updated"
else
  log "crypttab already has data"
fi
cat /etc/crypttab

if ! grep -qE '[[:space:]]/data[[:space:]]' /etc/fstab 2>/dev/null; then
  cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
  printf '\n# CHG-004 encrypted XFS data (83te 200G OS layout)\nUUID=%s  /data  xfs  defaults,noatime  0  0\n' "$DATA_FS_UUID" >> /etc/fstab
  log "fstab updated"
else
  log "fstab already has /data"
fi
grep /data /etc/fstab || true

mkdir -p /data
mountpoint -q /data || mount /data
df -hT /data

log "limine-mkinitcpio (UKI refresh)"
yes Y | limine-mkinitcpio || limine-mkinitcpio

log "Migrate Projects to /data"
SRC="$USER_HOME/Development/Projects"
PROJECTS_DST="/data/Development/Projects"
mkdir -p /data/Development

if [[ -L "$SRC" ]]; then
  log "Already symlink: $(readlink "$SRC")"
elif [[ -d "$SRC" ]]; then
  if [[ ! -e "${SRC}.bak.chg004" ]]; then
    mv "$SRC" "${SRC}.bak.chg004"
  fi
  mkdir -p "$PROJECTS_DST"
  rsync -aHAX --info=progress2 "${SRC}.bak.chg004/" "$PROJECTS_DST/"
  ln -sfn "$PROJECTS_DST" "$SRC"
  chown -h "$USER_NAME:$USER_NAME" "$SRC"
  chown -R "$USER_NAME:$USER_NAME" /data/Development
else
  mkdir -p "$PROJECTS_DST" "$(dirname "$SRC")"
  ln -sfn "$PROJECTS_DST" "$SRC"
  chown -h "$USER_NAME:$USER_NAME" "$SRC"
  chown -R "$USER_NAME:$USER_NAME" /data/Development
fi

log "Verification"
lsblk -f "$DISK"
df -hT / /data
echo "Projects → $(readlink -f "$SRC" 2>/dev/null || echo missing)"
echo "crypttab:"; cat /etc/crypttab
echo "fstab /data:"; grep /data /etc/fstab
log "FINISH_OK — reboot to verify dual LUKS unlock"
