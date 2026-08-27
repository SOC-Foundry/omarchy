#!/usr/bin/env bash
# CHG-014 prune — keep only the two newest Snapper snapshots.
#
# snapper delete A B C aborts the whole invocation if any ID is missing.
# This script deletes one ID at a time and clears broken metadata dirs.
#
# Run as root:
#   sudo bash scripts/chg014-prune.sh
set -u

if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: run as root (sudo bash scripts/chg014-prune.sh)"
  exit 1
fi

echo "==> remove broken snapshot metadata if present"
for n in 3 4 5 6 44; do
  if [[ -e /.snapshots/$n ]]; then
    echo "    clearing /.snapshots/$n"
    btrfs subvolume delete -c /.snapshots/$n/snapshot 2>/dev/null || true
    rm -rf /.snapshots/$n
  fi
done

echo "==> list snapshots"
mapfile -t nums < <(snapper --no-dbus -c root list --columns number 2>/dev/null \
  | awk 'NR>2 && $1+0 == $1 && $1 != "0" {print $1}')
echo "    ${#nums[@]} snapshots"

if ((${#nums[@]} <= 2)); then
  echo "    already at or below 2, nothing to delete"
else
  keep=("${nums[-2]}" "${nums[-1]}")
  echo "    keeping ${keep[*]}"
  for n in "${nums[@]:0:${#nums[@]}-2}"; do
    if snapper --no-dbus -c root delete "$n"; then
      echo "    deleted $n"
    else
      echo "    snapper delete $n failed, forcing"
      btrfs subvolume delete -c /.snapshots/$n/snapshot 2>/dev/null || true
      rm -rf /.snapshots/$n
    fi
  done
  echo "==> mark kept snapshots as cleanup=number"
  snapper --no-dbus -c root modify --cleanup-algorithm number "${keep[@]}" || true
fi

echo "==> remaining"
snapper --no-dbus -c root list || true

if command -v limine-snapper-sync >/dev/null 2>&1; then
  echo "==> limine-snapper-sync"
  limine-snapper-sync || true
fi

echo "==> usage"
df -h /
btrfs filesystem usage / | sed -n '1,16p'
