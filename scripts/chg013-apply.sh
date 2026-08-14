#!/usr/bin/env bash
# CHG-013 apply — Island desk setup on 83te (needs CHG-012)
#
# Super+Shift+I launch-or-focus Island. Super+Shift+Alt+I incognito.
# Does NOT change the xdg default browser (Chrome).
#
# Run as the desktop user (NOT root):
#   bash scripts/chg013-apply.sh
set -euo pipefail

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIND="$CFG/hypr/bindings.conf"
CHG_TAG="${CHG_TAG:-chg013}"
TS=$(date +%Y%m%d-%H%M%S)

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "$BIND" ]] || die "missing $BIND"
command -v island-browser-stable >/dev/null || die "island-browser-stable not on PATH (run CHG-012 first)"

log "Backing up bindings (tag=${CHG_TAG}.${TS})"
cp -a "$BIND" "$BIND.bak.${CHG_TAG}.${TS}"
echo "  $BIND → $BIND.bak.${CHG_TAG}.${TS}"

log "Island keybinds"
if grep -q 'CHG-013 Island' "$BIND"; then
  echo "  bindings.conf already has CHG-013 block"
else
  cat >>"$BIND" <<'EOF'

# CHG-013 Island — work browser (Chrome stays xdg default on Super+Shift+B)
bindd = SUPER SHIFT, I, Island, exec, omarchy-launch-or-focus ^island-browser$ "uwsm-app -- island-browser-stable"
bindd = SUPER SHIFT ALT, I, Island (incognito), exec, uwsm-app -- island-browser-stable --incognito
EOF
  echo "  appended CHG-013 binds to $BIND"
fi

if command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null || true
  hyprctl configerrors || true
fi

log "Done. Super+Shift+I → Island · Super+Shift+B still Chrome."
echo "  verify: fish $(cd "$(dirname "$0")" && pwd)/chg013-verify.fish"
