#!/usr/bin/env bash
# CHG-004: Complete XFS format on p3 (partition script failed at mkfs.xfs before xfsprogs was installed)
set -euo pipefail

P3_PART=/dev/nvme0n1p3
LUKS_DATA_NAME=data

[[ $EUID -eq 0 ]] || { echo "Run: sudo bash $0"; exit 1; }

command -v mkfs.xfs >/dev/null || pacman -S --noconfirm xfsprogs

if ! cryptsetup status "$LUKS_DATA_NAME" &>/dev/null; then
  cryptsetup open "$P3_PART" "$LUKS_DATA_NAME"
fi

if ! blkid -o value -s TYPE "/dev/mapper/$LUKS_DATA_NAME" 2>/dev/null | grep -q xfs; then
  mkfs.xfs -f -L data "/dev/mapper/$LUKS_DATA_NAME"
fi

cryptsetup close "$LUKS_DATA_NAME"

echo "XFS ready on p3. LUKS UUID: $(cryptsetup luksUUID $P3_PART)"
echo "Next: sudo bash scripts/chg004-postboot.sh"