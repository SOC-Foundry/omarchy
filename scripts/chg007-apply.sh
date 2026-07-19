#!/usr/bin/env bash
# CHG-007 apply — audio precedence + Rock EQ for Spotify/Chrome on 83te
#
# Phase 1: sink/source precedence (P30i → Lenovo USB-C → built-in)
# Phase 2: Rock EQ always-on for Spotify + Google Chrome; mic order for calls
# Network DSCP EF: already on LAN — intentionally NOT installed here
#
# Run as the desktop user (NOT root):
#   bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-apply.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
USER_NAME="${SUDO_USER:-${USER:-kthompson}}"
if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root (got uid 0)."
  echo "  bash $0"
  exit 1
fi

HOME_DIR="${HOME}"
CFG="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"
STATE="${XDG_STATE_HOME:-$HOME_DIR/.local/state}"
LOCAL_BIN="$HOME_DIR/.local/bin"
SYSTEMD_USER="$CFG/systemd/user"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v pactl >/dev/null || die "pactl missing (pipewire-pulse)"
command -v wpctl >/dev/null || die "wpctl missing (wireplumber)"
command -v systemctl >/dev/null || die "systemctl missing"

log "Backing up current configs"
TS=$(date +%Y%m%d-%H%M%S)
for d in \
  "$CFG/wireplumber/wireplumber.conf.d" \
  "$CFG/audio-eq" \
  "$CFG/pipewire/filter-chain.conf.d"
do
  if [[ -d "$d" ]]; then
    bak="${d}.bak.chg007.${TS}"
    cp -a "$d" "$bak"
    echo "  backed up $d → $bak"
  fi
done

log "Installing WirePlumber drop-ins"
mkdir -p "$CFG/wireplumber/wireplumber.conf.d"
install -m 0644 \
  "$REPO/config/wireplumber/wireplumber.conf.d/50-device-precedence.conf" \
  "$REPO/config/wireplumber/wireplumber.conf.d/51-bluetooth-quality.conf" \
  "$REPO/config/wireplumber/wireplumber.conf.d/bluetooth-a2dp-autoconnect.conf" \
  "$REPO/config/wireplumber/wireplumber.conf.d/52-stream-music-eq.conf" \
  "$CFG/wireplumber/wireplumber.conf.d/"

log "Installing Rock/EDM EQ presets"
mkdir -p "$CFG/audio-eq" "$CFG/pipewire/filter-chain.conf.d"
install -m 0644 \
  "$REPO/config/audio-eq/rock.conf" \
  "$REPO/config/audio-eq/edm.conf" \
  "$CFG/audio-eq/"
echo rock >"$CFG/audio-eq/state"
ln -sfn "$CFG/audio-eq/rock.conf" "$CFG/pipewire/filter-chain.conf.d/10-audio-eq.conf"

log "Installing helper binaries"
mkdir -p "$LOCAL_BIN"
install -m 0755 \
  "$REPO/bin/audio-precedence-follow" \
  "$REPO/bin/audio-precedence-watch" \
  "$LOCAL_BIN/"
# Keep existing audio-eq if present; otherwise ship a thin wrapper note
if [[ ! -x "$LOCAL_BIN/audio-eq" ]]; then
  echo "  note: ~/.local/bin/audio-eq not found — EQ cycle hotkey may be inactive"
fi

log "Installing user systemd unit"
mkdir -p "$SYSTEMD_USER"
install -m 0644 \
  "$REPO/config/systemd/user/audio-precedence-watch.service" \
  "$SYSTEMD_USER/"

log "Clearing sticky WirePlumber profile that forced built-in Off"
# WP stores Active Profile: off for sof_sdw — remove so device.profile can apply
PROF="$STATE/wireplumber/default-profile"
if [[ -f "$PROF" ]]; then
  cp -a "$PROF" "${PROF}.bak.chg007.${TS}"
  # Drop the sof_sdw off pin; keep other keys
  if command -v python3 >/dev/null; then
    python3 - <<'PY' "$PROF"
import sys, re
path = sys.argv[1]
text = open(path).read().splitlines()
out = []
for line in text:
    if "sof_sdw" in line and "=off" in line:
        continue
    out.append(line)
open(path, "w").write("\n".join(out) + ("\n" if out else ""))
PY
  else
    # sed fallback
    sed -i '/sof_sdw.*=off/d' "$PROF" || true
  fi
  echo "  scrubbed sof_sdw=off from $PROF"
fi

# Prefer EQ as configured default sink
NODES="$STATE/wireplumber/default-nodes"
mkdir -p "$(dirname "$NODES")"
cat >"$NODES" <<'EOF'
[default-nodes]
default.configured.audio.sink=effect_input.eq
EOF
echo "  wrote $NODES (default sink → effect_input.eq)"

log "Reloading user systemd + enabling watch service"
systemctl --user daemon-reload
systemctl --user enable audio-precedence-watch.service

log "Restarting WirePlumber + filter-chain (Rock EQ)"
systemctl --user restart wireplumber.service
# filter-chain is a separate user unit provided by pipewire package
systemctl --user enable filter-chain.service 2>/dev/null || true
systemctl --user restart filter-chain.service

# Give nodes a moment to appear
sleep 1.5

log "Applying precedence once"
"$LOCAL_BIN/audio-precedence-follow" --print || true

systemctl --user restart audio-precedence-watch.service

log "Quick status"
wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' || true
echo
pactl get-default-sink 2>/dev/null || true
pactl get-default-source 2>/dev/null || true
systemctl --user is-active filter-chain.service audio-precedence-watch.service wireplumber.service || true

cat <<EOF

CHG-007 apply complete.

Verify:
  fish $REPO/scripts/chg007-verify.fish

Manual checks:
  1. Spotify → should play through EQ Rock → P30i (if connected)
  2. Unpair/disconnect P30i → output falls to Lenovo USB-C
  3. Unplug Lenovo → output falls to Built-in Speakers
  4. Mic: default source follows P30i HFP (if active) → Lenovo → built-in dmic
  5. Meet/Zoom/Teams in Google Chrome use best mic; network EF is unchanged

EQ cycle hotkey still works: SUPER+CTRL+E (audio-eq cycle)
EOF
