#!/usr/bin/env bash
# Finish XFS format on already-opened or closed /data LUKS volume (p3).
# Use if chg004-partition.sh created p3 + LUKS but mkfs.xfs was missing.
set -euo pipefail

DISK=/dev/nvme0n1
P3=${DISK}p3
MAPPER_DATA=data

[[ $(id -u) -eq 0 ]] || { echo "run as root"; exit 1; }

if ! command -v mkfs.xfs >/dev/null 2>&1; then
  pacman -S --noconfirm xfsprogs
fi

if [[ ! -e /dev/mapper/$MAPPER_DATA ]]; then
  [[ -b $P3 ]] || { echo "missing $P3"; exit 1; }
  cryptsetup open "$P3" "$MAPPER_DATA"
fi

mkfs.xfs -f -L data "/dev/mapper/${MAPPER_DATA}"
lsblk -f "$DISK"
xfs_info "/dev/mapper/${MAPPER_DATA}"
echo "XFS ready. Run chg004-postboot.sh next."
