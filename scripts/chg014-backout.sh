#!/usr/bin/env bash
# CHG-014 backout — remove the pacman hook and restore Omarchy-ish Snapper defaults.
#
# Restores NUMBER_LIMIT=5, TIMELINE_CREATE=no. Does not recreate deleted snapshots.
# Does not re-enable snapper-timeline.timer (that was the bug).
#
# Run as the desktop user:
#   bash scripts/chg014-backout.sh
set -euo pipefail

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi

log() { printf '\n==> %s\n' "$*"; }

log "Remove pacman hook"
sudo rm -f /etc/pacman.d/hooks/05-snapper-pacman-pre.hook /usr/local/sbin/snapper-pacman-pre

log "Restore Omarchy-shipped Snapper intent (keep 5, no timeline)"
sudo snapper --no-dbus -c root set-config \
  NUMBER_CLEANUP=yes \
  NUMBER_MIN_AGE=3600 \
  NUMBER_LIMIT=5 \
  NUMBER_LIMIT_IMPORTANT=5 \
  TIMELINE_CREATE=no \
  TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=0 \
  TIMELINE_LIMIT_DAILY=0 \
  TIMELINE_LIMIT_WEEKLY=0 \
  TIMELINE_LIMIT_MONTHLY=0 \
  TIMELINE_LIMIT_QUARTERLY=0 \
  TIMELINE_LIMIT_YEARLY=0 || true

sudo systemctl disable --now snapper-timeline.timer >/dev/null 2>&1 || true
sudo systemctl disable --now snapper-boot.timer >/dev/null 2>&1 || true
# leave cleanup timer enabled — it is what Omarchy forgot

if [[ -f /etc/default/limine ]]; then
  sudo sed -i 's/^MAX_SNAPSHOT_ENTRIES=.*/MAX_SNAPSHOT_ENTRIES=5/' /etc/default/limine
fi

log "Remove PATH wrapper and post-update hook"
rm -f "$HOME/.local/bin/omarchy-snapshot"
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/post-update.d/snapper-pacman-policy"

if command -v limine-snapper-sync >/dev/null 2>&1; then
  sudo limine-snapper-sync || true
fi

log "Backout complete. Deleted snapshots are gone for good."
