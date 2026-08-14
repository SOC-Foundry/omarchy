#!/usr/bin/env bash
# CHG-012 backout — remove Island Enterprise Browser
#
# Restores hyprland.conf + flags from the newest *.bak.chg012.* then
# uninstalls the pacman package. User profile under ~/.config/island is left.
set -euo pipefail

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
CHG_TAG="${CHG_TAG:-chg012}"

log() { printf '\n==> %s\n' "$*"; }

restore_latest() {
  local dest="$1"
  local glob="$2"
  local latest
  latest=$(ls -1t $glob 2>/dev/null | head -1 || true)
  if [[ -n "${latest:-}" && -f "$latest" ]]; then
    cp -a "$latest" "$dest"
    echo "  restored $dest ← $latest"
    return 0
  fi
  return 1
}

log "Restoring user-space backups (tag=${CHG_TAG})"
if restore_latest "$CFG/hypr/hyprland.conf" "$CFG/hypr/hyprland.conf.bak.${CHG_TAG}.*"; then
  :
elif [[ -f "$CFG/hypr/hyprland.conf" ]] && grep -q 'CHG-012 Island' "$CFG/hypr/hyprland.conf"; then
  tmp=$(mktemp)
  awk '
    /# CHG-012 Island/ { skip=1; next }
    skip && /^windowrule = tag \+chromium-based-browser, match:class \(\[Ii\]sland/ { skip=0; next }
    { print }
  ' "$CFG/hypr/hyprland.conf" >"$tmp"
  mv "$tmp" "$CFG/hypr/hyprland.conf"
  echo "  stripped CHG-012 block from $CFG/hypr/hyprland.conf"
fi

if restore_latest "$CFG/island-browser-flags.conf" "$CFG/island-browser-flags.conf.bak.${CHG_TAG}.*"; then
  :
else
  rm -f "$CFG/island-browser-flags.conf"
  echo "  removed $CFG/island-browser-flags.conf"
fi

if command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null || true
fi

log "Removing pacman package (sudo)"
if pacman -Q island-browser-stable >/dev/null 2>&1; then
  sudo pacman -Rns --noconfirm island-browser-stable
else
  echo "  island-browser-stable not installed"
fi

echo
echo "Profile left in place: ~/.config/island  (delete by hand if you want a clean slate)"
echo "Vendor .deb in the kit is unchanged."
