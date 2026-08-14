#!/usr/bin/env bash
# CHG-012 apply — Island Enterprise Browser on Arch (83te)
#
# Converts the vendor .deb in the kit root into a pacman package, installs it,
# writes Wayland flags, and tags Island as a chromium-based Hyprland window.
# Does NOT change the default browser.
#
# Run as the desktop user (NOT root):
#   bash scripts/chg012-apply.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$REPO/pkg/island-browser-stable"
DEB="$REPO/island-browser-stable_150.1.96.29-1_amd64.deb"
BUILD="${TMPDIR:-/tmp}/chg012-island-browser"
CHG_TAG="${CHG_TAG:-chg012}"

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root (got uid 0)."
  echo "  bash $0"
  exit 1
fi

HOME_DIR="${HOME}"
CFG="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "$DEB" ]] || die "missing installer: $DEB"
[[ -f "$PKG_DIR/PKGBUILD" ]] || die "missing $PKG_DIR/PKGBUILD"
command -v makepkg >/dev/null || die "makepkg missing (pacman)"
command -v sudo >/dev/null || die "sudo missing"

TS=$(date +%Y%m%d-%H%M%S)

log "Backing up user-space files (tag=${CHG_TAG}.${TS})"
if [[ -f "$CFG/hypr/hyprland.conf" ]]; then
  bak="$CFG/hypr/hyprland.conf.bak.${CHG_TAG}.${TS}"
  cp -a "$CFG/hypr/hyprland.conf" "$bak"
  echo "  $CFG/hypr/hyprland.conf → $bak"
fi
if [[ -f "$CFG/island-browser-flags.conf" ]]; then
  bak="$CFG/island-browser-flags.conf.bak.${CHG_TAG}.${TS}"
  cp -a "$CFG/island-browser-flags.conf" "$bak"
  echo "  $CFG/island-browser-flags.conf → $bak"
fi

log "Staging makepkg tree in $BUILD"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cp -a "$PKG_DIR/PKGBUILD" "$PKG_DIR/island-browser-stable.sh" "$PKG_DIR/island-browser-stable.install" "$BUILD/"
ln -s "$DEB" "$BUILD/island-browser-stable_150.1.96.29-1_amd64.deb"

log "Building island-browser-stable (makepkg)"
(
  cd "$BUILD"
  makepkg -f --noconfirm
)

PKG=$(ls "$BUILD"/island-browser-stable-*.pkg.tar.zst | head -1)
[[ -n "$PKG" && -f "$PKG" ]] || die "makepkg produced no package"
echo "  built $PKG"

log "Installing with pacman (sudo)"
sudo pacman -U --noconfirm "$PKG"

log "Wayland flags (~/.config/island-browser-flags.conf)"
mkdir -p "$CFG"
if [[ ! -f "$CFG/island-browser-flags.conf" ]]; then
  cat >"$CFG/island-browser-flags.conf" <<'EOF'
# CHG-012 Island Enterprise Browser — Wayland (Omarchy / Hyprland)
# Do not load Omarchy's copy-url Chromium extension here; Island is managed.
--ozone-platform=wayland
--ozone-platform-hint=wayland
--enable-features=TouchpadOverscrollHistoryNavigation
EOF
  echo "  wrote $CFG/island-browser-flags.conf"
else
  echo "  left existing $CFG/island-browser-flags.conf in place"
fi

log "Hyprland window rule (tag as chromium-based-browser)"
HYPR="$CFG/hypr/hyprland.conf"
if [[ -f "$HYPR" ]]; then
  if grep -q 'CHG-012 Island' "$HYPR"; then
    echo "  hyprland.conf already has CHG-012 block"
  else
    cat >>"$HYPR" <<'EOF'
# CHG-012 Island — tag as chromium-based (tile + opacity)
windowrule = tag +chromium-based-browser, match:class ([Ii]sland|island-browser|org\.island\.Island)
EOF
    echo "  appended CHG-012 windowrule to $HYPR"
  fi
  if command -v hyprctl >/dev/null; then
    hyprctl reload >/dev/null || true
    hyprctl configerrors || true
  fi
fi

if command -v omarchy >/dev/null && omarchy restart --help >/dev/null 2>&1; then
  log "Refresh Walker so Island appears in the launcher"
  omarchy restart walker >/dev/null 2>&1 || true
fi

log "Done. Island is installed; default browser is unchanged."
echo "  launch: island-browser-stable"
echo "  walker: Island"
echo "  verify: fish $REPO/scripts/chg012-verify.fish"
