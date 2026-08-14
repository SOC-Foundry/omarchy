#!/usr/bin/env bash
# CHG-013 backout — remove Island desk binds
set -euo pipefail

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIND="$CFG/hypr/bindings.conf"
CHG_TAG="${CHG_TAG:-chg013}"

log() { printf '\n==> %s\n' "$*"; }

restore_latest() {
  local dest="$1"
  local latest
  latest=$(ls -1t "$dest".bak."${CHG_TAG}".* 2>/dev/null | head -1 || true)
  if [[ -n "${latest:-}" && -f "$latest" ]]; then
    cp -a "$latest" "$dest"
    echo "  restored $dest ← $latest"
    return 0
  fi
  return 1
}

log "Restoring bindings"
if restore_latest "$BIND"; then
  :
elif [[ -f "$BIND" ]] && grep -q 'CHG-013 Island' "$BIND"; then
  tmp=$(mktemp)
  awk '
    /^# CHG-013 Island/ { skip=1; next }
    skip && /^bindd = SUPER SHIFT ALT, I, Island/ { skip=0; next }
    skip && /^bindd = SUPER SHIFT, I, Island/ { next }
    skip && /^$/ { skip=0; next }
    { print }
  ' "$BIND" >"$tmp"
  mv "$tmp" "$BIND"
  echo "  stripped CHG-013 block from $BIND"
else
  echo "  nothing to restore"
fi

if command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null || true
fi

echo "Island package and ~/.config/island profile are left in place (see CHG-012 backout)."
