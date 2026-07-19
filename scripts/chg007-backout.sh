#!/usr/bin/env bash
# CHG-007 backout — restore pre-change audio config on 83te
#
# Modes:
#   bash scripts/chg007-backout.sh              # full revert (default)
#   bash scripts/chg007-backout.sh --soft       # stop watch + EQ only; keep WP drop-ins
#   bash scripts/chg007-backout.sh --from-bak   # restore newest *.bak.chg007.* trees
#
# Run as the desktop user (NOT root).
set -euo pipefail

MODE=full
for a in "$@"; do
  case "$a" in
    --soft) MODE=soft ;;
    --from-bak|full) MODE=full ;;
    --help|-h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $a (try --help)" >&2
      exit 1
      ;;
  esac
done

if [[ $(id -u) -eq 0 ]]; then
  echo "ERROR: run as desktop user, not root."
  exit 1
fi

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="$HOME/.local/bin"
TS=$(date +%Y%m%d-%H%M%S)

log() { printf '\n==> %s\n' "$*"; }
ok()  { printf '  OK  %s\n' "$*"; }

newest_bak() {
  # $1 = config path e.g. $CFG/wireplumber/wireplumber.conf.d
  local base="$1" hit="" stamp
  for stamp in chg007 chg008 chg006 chg005; do
    hit=$(ls -1d ${base}.bak.${stamp}.* 2>/dev/null | sort | tail -1 || true)
    [[ -n "$hit" ]] && break
  done
  echo "$hit"
}

log "CHG-007 backout mode=$MODE"

# Always stop the follower first so it cannot re-apply mid-revert
if systemctl --user is-enabled audio-precedence-watch.service >/dev/null 2>&1 \
   || systemctl --user is-active audio-precedence-watch.service >/dev/null 2>&1; then
  systemctl --user disable --now audio-precedence-watch.service 2>/dev/null || true
  ok "disabled audio-precedence-watch.service"
else
  ok "audio-precedence-watch already off"
fi

if [[ "$MODE" == soft ]]; then
  systemctl --user stop filter-chain.service 2>/dev/null || true
  systemctl --user disable filter-chain.service 2>/dev/null || true
  rm -f "$CFG/pipewire/filter-chain.conf.d/10-audio-eq.conf"
  # Point default at raw hardware if EQ was default
  if command -v pactl >/dev/null; then
    hw=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | rg 'bluez_output|Lenovo|sof_sdw' | head -1 || true)
    if [[ -n "${hw:-}" ]]; then
      pactl set-default-sink "$hw" 2>/dev/null || true
      ok "default sink → $hw"
    fi
  fi
  systemctl --user restart wireplumber.service 2>/dev/null || true
  log "Soft backout done (WP precedence drop-ins still installed)."
  exit 0
fi

# --- Full backout ---
log "Stopping Rock EQ (filter-chain)"
systemctl --user stop filter-chain.service 2>/dev/null || true
systemctl --user disable filter-chain.service 2>/dev/null || true
rm -f "$CFG/pipewire/filter-chain.conf.d/10-audio-eq.conf"
ok "filter-chain stopped; EQ drop-in removed"

log "Removing CHG-007 WirePlumber drop-ins (keep pre-existing BT quality if bak restores)"
# Prefer restore from bak; else delete only CHG-007 files
WP_DIR="$CFG/wireplumber/wireplumber.conf.d"
WP_BAK=$(newest_bak "$WP_DIR")
if [[ -n "$WP_BAK" && -d "$WP_BAK" ]]; then
  log "Restoring WirePlumber conf.d from $WP_BAK"
  mkdir -p "${WP_DIR}.pre-backout.${TS}"
  cp -a "$WP_DIR/." "${WP_DIR}.pre-backout.${TS}/" 2>/dev/null || true
  rm -rf "$WP_DIR"
  cp -a "$WP_BAK" "$WP_DIR"
  ok "restored $WP_DIR"
else
  log "No WP bak found — deleting CHG-007-only files"
  rm -f \
    "$WP_DIR/50-device-precedence.conf" \
    "$WP_DIR/52-stream-music-eq.conf"
  # leave 51-bluetooth-quality + bluetooth-a2dp-autoconnect if they pre-existed
  ok "removed 50-device-precedence + 52-stream-music-eq"
fi

log "Restoring audio-eq presets (optional)"
EQ_DIR="$CFG/audio-eq"
EQ_BAK=$(newest_bak "$EQ_DIR")
if [[ -n "$EQ_BAK" && -d "$EQ_BAK" ]]; then
  mkdir -p "${EQ_DIR}.pre-backout.${TS}"
  cp -a "$EQ_DIR/." "${EQ_DIR}.pre-backout.${TS}/" 2>/dev/null || true
  rm -rf "$EQ_DIR"
  cp -a "$EQ_BAK" "$EQ_DIR"
  ok "restored $EQ_DIR"
else
  ok "no audio-eq bak — leaving $EQ_DIR as-is"
fi

FC_DIR="$CFG/pipewire/filter-chain.conf.d"
FC_BAK=$(newest_bak "$FC_DIR")
if [[ -n "$FC_BAK" && -d "$FC_BAK" ]]; then
  mkdir -p "${FC_DIR}.pre-backout.${TS}"
  cp -a "$FC_DIR/." "${FC_DIR}.pre-backout.${TS}/" 2>/dev/null || true
  rm -rf "$FC_DIR"
  cp -a "$FC_BAK" "$FC_DIR"
  ok "restored $FC_DIR"
fi

log "Removing CHG-007 helpers (keep audio-eq if pre-existing)"
rm -f \
  "$LOCAL_BIN/audio-precedence-follow" \
  "$LOCAL_BIN/audio-precedence-watch"
if [[ -f "$LOCAL_BIN/audio-eq.bak.chg007" ]]; then
  cp -a "$LOCAL_BIN/audio-eq.bak.chg007" "$LOCAL_BIN/audio-eq"
  ok "restored audio-eq from bak.chg007"
elif [[ -f "$LOCAL_BIN/audio-eq.bak.chg006" ]]; then
  cp -a "$LOCAL_BIN/audio-eq.bak.chg006" "$LOCAL_BIN/audio-eq"
  ok "restored audio-eq from bak.chg006"
elif [[ -f "$LOCAL_BIN/audio-eq.bak.chg005" ]]; then
  cp -a "$LOCAL_BIN/audio-eq.bak.chg005" "$LOCAL_BIN/audio-eq"
  ok "restored audio-eq from bak.chg005"
else
  ok "left audio-eq as-is (no bak)"
fi

log "Removing user unit"
rm -f "$CFG/systemd/user/audio-precedence-watch.service"
rm -f "$CFG/systemd/user/default.target.wants/audio-precedence-watch.service"
systemctl --user daemon-reload
ok "unit removed"

log "Restoring WirePlumber default-profile pin (if bak exists)"
PROF="$STATE/wireplumber/default-profile"
PROF_BAK=""
# newest_bak expects prefix; file is default-profile.bak.chg007.TS
PROF_BAK=$(ls -1 "$PROF".bak.chg007.* 2>/dev/null | sort | tail -1 || true)
if [[ -z "${PROF_BAK:-}" ]]; then
  PROF_BAK=$(ls -1 "$PROF".bak.chg006.* 2>/dev/null | sort | tail -1 || true)
fi
if [[ -z "${PROF_BAK:-}" ]]; then
  PROF_BAK=$(ls -1 "$PROF".bak.chg005.* 2>/dev/null | sort | tail -1 || true)
fi
if [[ -n "${PROF_BAK:-}" && -f "$PROF_BAK" ]]; then
  cp -a "$PROF_BAK" "$PROF"
  ok "restored default-profile from $PROF_BAK"
else
  ok "no default-profile bak — leaving state"
fi

# Clear EQ as configured default so WP picks best hardware again
NODES="$STATE/wireplumber/default-nodes"
if [[ -f "$NODES" ]]; then
  cp -a "$NODES" "${NODES}.pre-backout.${TS}"
  # Remove EQ preference; empty or drop effect_input.eq line
  if rg -q 'effect_input\.eq' "$NODES" 2>/dev/null; then
    cat >"$NODES" <<'EOF'
[default-nodes]
EOF
    ok "cleared effect_input.eq from default-nodes"
  fi
fi

log "Restarting WirePlumber"
systemctl --user restart wireplumber.service
sleep 1.5

if command -v pactl >/dev/null; then
  # Prefer P30i if present, else Lenovo, else anything non-null
  hw=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | rg 'bluez_output\.F4_B6_2D_75_CE_92' | head -1 || true)
  if [[ -z "${hw:-}" ]]; then
    hw=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | rg 'Lenovo_USB-C|bluez_output' | head -1 || true)
  fi
  if [[ -n "${hw:-}" ]]; then
    pactl set-default-sink "$hw" 2>/dev/null || true
    ok "default sink → $hw"
  fi
  src=$(pactl list short sources 2>/dev/null | awk '{print $2}' | rg -v '\.monitor$' | rg 'Lenovo_USB-C|bluez_input|sof_sdw' | head -1 || true)
  if [[ -n "${src:-}" ]]; then
    pactl set-default-source "$src" 2>/dev/null || true
    ok "default source → $src"
  fi
fi

log "Post-backout status"
systemctl --user is-active wireplumber.service filter-chain.service audio-precedence-watch.service 2>/dev/null || true
pactl get-default-sink 2>/dev/null || true
pactl get-default-source 2>/dev/null || true
wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' || true

cat <<EOF

CHG-007 full backout complete.

Verify audio works (Spotify / Chrome / a quick mic test in Meet).
If something is still wrong, re-check:

  ls -d ~/.config/wireplumber/wireplumber.conf.d.bak.chg007.*
  ls -d ~/.config/audio-eq.bak.chg007.*
  systemctl --user status wireplumber

To re-apply CHG-007 later:
  bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-apply.sh
EOF
