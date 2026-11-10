#!/usr/bin/env bash
# CHG-014 apply — Snapper: pre-pacman only, keep last 2
#
# Installs the pacman hook, Snapper keys, timers, PATH wrapper, and
# omarchy post-update hook. Does not delete existing snapshots
# (use scripts/chg014-prune.sh for that).
#
# Run as the desktop user. Will sudo for system files.
#   bash scripts/chg014-apply.sh
set -euo pipefail

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root (script sudo's the system bits)."
  exit 1
fi

KIT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$KIT/scripts/chg014-files"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
CHG_TAG="${CHG_TAG:-chg014}"
TS=$(date +%Y%m%d-%H%M%S)

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$SRC" ]] || die "missing $SRC"
command -v snapper >/dev/null || die "snapper not installed"
command -v sudo >/dev/null || die "sudo not installed"

backup() {
  local f=$1
  if [[ -e $f ]]; then
    sudo cp -a "$f" "${f}.bak.${CHG_TAG}.${TS}"
    echo "  backup $f → ${f}.bak.${CHG_TAG}.${TS}"
  fi
}

log "Install pacman hook + helper"
backup /usr/local/sbin/snapper-pacman-pre
backup /etc/pacman.d/hooks/05-snapper-pacman-pre.hook
sudo install -d /usr/local/sbin /etc/pacman.d/hooks
sudo install -m 0755 "$SRC/snapper-pacman-pre" /usr/local/sbin/snapper-pacman-pre
sudo install -m 0644 "$SRC/05-snapper-pacman-pre.hook" /etc/pacman.d/hooks/05-snapper-pacman-pre.hook

log "Snapper policy: no timeline, keep 2 numbered snapshots"
if [[ -f /etc/snapper/configs/root ]]; then
  backup /etc/snapper/configs/root
fi
sudo snapper --no-dbus -c root set-config \
  NUMBER_CLEANUP=yes \
  NUMBER_MIN_AGE=0 \
  NUMBER_LIMIT=2 \
  NUMBER_LIMIT_IMPORTANT=2 \
  TIMELINE_CREATE=no \
  TIMELINE_CLEANUP=yes \
  TIMELINE_MIN_AGE=0 \
  TIMELINE_LIMIT_HOURLY=0 \
  TIMELINE_LIMIT_DAILY=0 \
  TIMELINE_LIMIT_WEEKLY=0 \
  TIMELINE_LIMIT_MONTHLY=0 \
  TIMELINE_LIMIT_QUARTERLY=0 \
  TIMELINE_LIMIT_YEARLY=0 \
  EMPTY_PRE_POST_CLEANUP=yes \
  EMPTY_PRE_POST_MIN_AGE=0

log "Timers: timeline/boot off, cleanup on"
sudo systemctl disable --now snapper-timeline.timer
sudo systemctl disable --now snapper-boot.timer || true
sudo systemctl enable --now snapper-cleanup.timer

# Omarchy 4.5 keeps the boot-menu cap in limine-entry-tool drop-ins (ships 6).
# /etc/default/limine overrides those, and older hosts already have the key.
if [[ -f /etc/default/limine ]]; then
  backup /etc/default/limine
  if grep -q '^MAX_SNAPSHOT_ENTRIES=' /etc/default/limine; then
    sudo sed -i 's/^MAX_SNAPSHOT_ENTRIES=.*/MAX_SNAPSHOT_ENTRIES=2/' /etc/default/limine
  else
    printf '\n# CHG-014 — boot menu keeps the last 2 snapshots.\nMAX_SNAPSHOT_ENTRIES=2\n' | sudo tee -a /etc/default/limine >/dev/null
  fi
fi

log "PATH wrapper so omarchy-update does not consume both snapshot slots"
mkdir -p "$HOME/.local/bin"
if [[ -e $HOME/.local/bin/omarchy-snapshot ]]; then
  cp -a "$HOME/.local/bin/omarchy-snapshot" "$HOME/.local/bin/omarchy-snapshot.bak.${CHG_TAG}.${TS}"
fi
install -m 0755 "$SRC/omarchy-snapshot" "$HOME/.local/bin/omarchy-snapshot"

log "omarchy post-update hook (re-apply if distro copies NUMBER_LIMIT=5)"
HOOK_DIR="$CFG/omarchy/hooks/post-update.d"
mkdir -p "$HOOK_DIR"
if [[ -e $HOOK_DIR/snapper-pacman-policy ]]; then
  cp -a "$HOOK_DIR/snapper-pacman-policy" "$HOOK_DIR/snapper-pacman-policy.bak.${CHG_TAG}.${TS}"
fi
install -m 0755 "$SRC/snapper-pacman-policy" "$HOOK_DIR/snapper-pacman-policy"

log "Done. Existing snapshots are unchanged."
echo "  To drop everything except the last 2: sudo bash $KIT/scripts/chg014-prune.sh"
echo "  Verify: fish $KIT/scripts/chg014-verify.fish"
