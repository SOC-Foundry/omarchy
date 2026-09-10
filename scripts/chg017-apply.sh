#!/usr/bin/env bash
# CHG-017 apply — three-tier failover: P30i → Lenovo USB-C → built-in
# Keeps CHG-010 sof PCM map; drops AUX 3.5mm from automatic pick order.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
TS=$(date +%Y%m%d-%H%M%S)
TAG=chg017

if [[ -d "$CFG/wireplumber/wireplumber.conf.d" ]]; then
  cp -a "$CFG/wireplumber/wireplumber.conf.d" "$CFG/wireplumber/wireplumber.conf.d.bak.${TAG}.${TS}"
  echo "backed up wireplumber.conf.d → *.bak.${TAG}.${TS}"
fi
if [[ -f "$HOME/.local/bin/audio-precedence-follow" ]]; then
  cp -a "$HOME/.local/bin/audio-precedence-follow" "$HOME/.local/bin/audio-precedence-follow.bak.${TAG}.${TS}"
fi

install -m 0644 \
  "$REPO/config/wireplumber/wireplumber.conf.d/50-device-precedence.conf" \
  "$CFG/wireplumber/wireplumber.conf.d/"
install -m 0755 \
  "$REPO/bin/audio-precedence-follow" \
  "$HOME/.local/bin/audio-precedence-follow"

systemctl --user restart wireplumber.service
sleep 1.5
"$HOME/.local/bin/audio-precedence-follow" --print || true
systemctl --user restart audio-precedence-watch.service
echo "chg017 apply complete"
wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' || true
