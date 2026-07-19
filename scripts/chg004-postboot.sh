#!/usr/bin/env bash
# CHG-004 post steps: crypttab, fstab, limine UKI, migrate Projects to /data, symlink.
set -euo pipefail

DISK=/dev/nvme0n1
P3=${DISK}p3
MAPPER_DATA=data
PROJECTS_SRC="${HOME_OVERRIDE:-/home/kthompson}/Development/Projects"
PROJECTS_DST="/data/Development/Projects"
USER_NAME="${SUDO_USER:-kthompson}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ $(id -u) -eq 0 ]] || die "run as root (sudo bash $0)"

if ! command -v mkfs.xfs >/dev/null 2>&1; then
  pacman -S --noconfirm xfsprogs
fi

# Open data mapper if needed
if [[ ! -e /dev/mapper/$MAPPER_DATA ]]; then
  [[ -b $P3 ]] || die "missing $P3 — run partition script first"
  log "Opening LUKS $P3 as $MAPPER_DATA (enter data passphrase)"
  cryptsetup open "$P3" "$MAPPER_DATA"
fi

# Ensure XFS
FSTYPE=$(blkid -o value -s TYPE "/dev/mapper/$MAPPER_DATA" || true)
if [[ "$FSTYPE" != xfs ]]; then
  log "Formatting XFS on mapper (was: ${FSTYPE:-unknown})"
  mkfs.xfs -f -L data "/dev/mapper/$MAPPER_DATA"
fi

DATA_LUKS_UUID=$(cryptsetup luksUUID "$P3")
DATA_FS_UUID=$(blkid -o value -s UUID "/dev/mapper/$MAPPER_DATA")
log "data LUKS UUID=$DATA_LUKS_UUID"
log "data XFS  UUID=$DATA_FS_UUID"

# crypttab
if grep -qE '^[[:space:]]*data[[:space:]]' /etc/crypttab 2>/dev/null; then
  log "crypttab already has data entry — leaving as-is"
else
  log "Appending data entry to /etc/crypttab"
  cp -a /etc/crypttab "/etc/crypttab.bak.$(date +%Y%m%d-%H%M%S)"
  printf 'data  UUID=%s  none  luks\n' "$DATA_LUKS_UUID" >> /etc/crypttab
fi
cat /etc/crypttab

# fstab
if grep -qE '[[:space:]]/data[[:space:]]' /etc/fstab 2>/dev/null; then
  log "fstab already has /data — leaving as-is"
else
  log "Appending /data to /etc/fstab"
  cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
  printf '\n# CHG-004 encrypted XFS data\nUUID=%s  /data  xfs  defaults,noatime  0  0\n' "$DATA_FS_UUID" >> /etc/fstab
fi
grep -E '/data|crypt' /etc/fstab || true

log "Creating /data and mounting"
mkdir -p /data
if ! mountpoint -q /data; then
  mount /data
fi
df -hT /data

log "Regenerating initramfs/UKI via limine-mkinitcpio (answer Y if prompted)"
# Non-interactive where possible
if command -v limine-mkinitcpio >/dev/null 2>&1; then
  # Omarchy expects confirmation; try yes pipe
  yes Y | limine-mkinitcpio || limine-mkinitcpio
else
  die "limine-mkinitcpio not found"
fi

log "Migrating Projects → ${PROJECTS_DST}"
mkdir -p /data/Development
SRC="$USER_HOME/Development/Projects"
if [[ -L "$SRC" ]]; then
  log "$SRC is already a symlink: $(readlink -f "$SRC" || readlink "$SRC")"
elif [[ -d "$SRC" ]]; then
  # Keep original on btrfs as .bak
  if [[ ! -e "${SRC}.bak.chg004" ]]; then
    log "Renaming original tree to ${SRC}.bak.chg004"
    mv "$SRC" "${SRC}.bak.chg004"
  fi
  mkdir -p "$PROJECTS_DST"
  rsync -aHAX --info=progress2 "${SRC}.bak.chg004/" "$PROJECTS_DST/"
  ln -sfn "$PROJECTS_DST" "$SRC"
  chown -h "$USER_NAME:$USER_NAME" "$SRC"
  chown -R "$USER_NAME:$USER_NAME" /data/Development
else
  log "No Projects dir at $SRC — creating empty structure"
  mkdir -p "$PROJECTS_DST"
  mkdir -p "$(dirname "$SRC")"
  ln -sfn "$PROJECTS_DST" "$SRC"
  chown -h "$USER_NAME:$USER_NAME" "$SRC"
  chown -R "$USER_NAME:$USER_NAME" /data/Development
fi

log "Verification"
lsblk -f "$DISK"
df -hT / /data
echo "Projects symlink: $(readlink -f "$SRC" 2>/dev/null || echo missing)"
ls -la "$(dirname "$SRC")" | head -20
echo
echo "crypttab:"
cat /etc/crypttab
echo
echo "fstab /data line:"
grep /data /etc/fstab || true

cat <<EOF

CHG-004 postboot complete on this live session.

REQUIRED: reboot and confirm dual LUKS unlock + /data auto-mount:

  sudo reboot

Then:
  lsblk -f /dev/nvme0n1
  mount | grep /data
  df -hT / /data
  readlink -f ~/Development/Projects

After reboot confidence, reclaim btrfs space:
  rm -rf ~/Projects.chg004.bak ~/Development/Projects.bak.chg004

EOF
