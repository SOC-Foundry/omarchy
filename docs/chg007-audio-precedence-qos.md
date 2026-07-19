# CHG-007 — Audio precedence + Rock EQ (83te)

**Host:** `83te` — Lenovo Yoga 7 2-in-1 16IPH11 (Omarchy / Arch, PipeWire + WirePlumber)  
**Date:** 2026-07-19  
**Status:** Applied  
**Network note:** Meet / Zoom / Teams already marked **EF (DSCP 46)** on the LAN. This change does **not** install host nftables/CAKE.

---

## Summary

| Phase | What |
|-------|------|
| **1 — Precedence** | Output: soundcore P30i → Lenovo USB-C → built-in speakers. Input walks the same order among available mics (camera last). |
| **2 — App path** | Spotify + Google Chrome → Rock EQ → best hardware sink. Call mics use precedence. No host DSCP. |

### Decisions locked

1. Mic walks full input precedence among **available** sources  
2. Rock EQ always-on for music path  
3. Google Chrome only (no PWA friction)  
4. No host DSCP — network already has EF  

---

## Device order

| Priority | Output (sink) | Input (source) |
|----------|---------------|----------------|
| 1 | soundcore P30i (BT A2DP) | soundcore P30i mic (HFP only; A2DP has no capture) |
| 2 | Lenovo USB-C Wired In-Ear | Lenovo USB-C mic |
| 3 | Built-in speakers (`pro-output-0`) | Built-in dmic (`pro-input-1`) |
| last | — | USB camera mic |

### App audio

| App | Behavior |
|-----|----------|
| Spotify | Rock EQ (`effect_input.eq`) |
| Google Chrome (YouTube TV, Meet tabs, etc.) | Rock EQ |
| Meet / Zoom / Teams | Best mic via precedence; media EF on network |
| EQ default | **Rock** always-on (`filter-chain.service`) |

---

## Layout in this repo

```
omarchy/
├── README.md
├── docs/chg007-audio-precedence-qos.md   # this file
├── bin/
│   ├── audio-precedence-follow
│   └── audio-precedence-watch
├── config/
│   ├── audio-eq/{rock,edm}.conf
│   ├── systemd/user/audio-precedence-watch.service
│   └── wireplumber/wireplumber.conf.d/
│       ├── 50-device-precedence.conf
│       ├── 51-bluetooth-quality.conf
│       ├── 52-stream-music-eq.conf
│       └── bluetooth-a2dp-autoconnect.conf
└── scripts/
    ├── chg007-apply.sh
    ├── chg007-verify.fish
    └── chg007-backout.sh
```

---

## Apply

Run as the **desktop user** (not root):

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-apply.sh
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg007-verify.fish
```

What apply does:

1. Backs up `~/.config/wireplumber/wireplumber.conf.d`, `~/.config/audio-eq`, and filter-chain drop-ins to `*.bak.chg007.<timestamp>`  
2. Installs WirePlumber + EQ configs and helpers into `~/.local/bin`  
3. Clears sticky `sof_sdw=off` profile state  
4. Sets default configured sink to `effect_input.eq`  
5. Enables/restarts `filter-chain` (Rock), `wireplumber`, `audio-precedence-watch`

### Runtime model

```
Spotify / Chrome
       │
       ▼
 effect_input.eq   (Rock / optional EDM via SUPER+CTRL+E)
       │
       ▼
 effect_output.eq  ──follow──► best hardware sink
                               (P30i → Lenovo → built-in)

Meet/Zoom/Teams capture ──► best source
                               (P30i HFP → Lenovo → dmic → camera)
```

`audio-precedence-watch` runs `pactl subscribe` and re-glues EQ output + default source when devices change.

### Hotkeys

| Key | Action |
|-----|--------|
| `SUPER+CTRL+E` | Cycle EQ: rock → edm → off |
| `SUPER+CTRL+SHIFT+E` | EQ status |

---

## Backout / revert

Prefer the automated script. It restores the newest `*.bak.chg007.*` trees created by apply when present.

### Option A — Automated full backout (recommended)

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-backout.sh
```

This will:

1. Disable and stop `audio-precedence-watch.service`  
2. Stop and disable `filter-chain.service`; remove EQ drop-in link  
3. Restore `~/.config/wireplumber/wireplumber.conf.d` from newest `*.bak.chg007.*` (or delete only CHG-007 files if no bak)  
4. Restore `~/.config/audio-eq` and filter-chain conf.d from bak when available  
5. Remove `~/.local/bin/audio-precedence-{follow,watch}`  
6. Restore `~/.local/bin/audio-eq` from `audio-eq.bak.chg007` if that bak exists  
7. Remove the user systemd unit and reload  
8. Restore `default-profile` bak if present; clear `effect_input.eq` from default-nodes  
9. Restart WirePlumber and set default sink/source to live hardware  

Before overwriting live trees, backout copies the current CHG-007 state to `*.pre-backout.<timestamp>` so you can undo a bad revert.

### Option B — Soft backout (EQ + watcher only)

Keeps device-precedence WirePlumber rules; only removes always-on Rock EQ and the follower:

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-backout.sh --soft
```

### Option C — Manual full backout

Use if the script is unavailable. Still run as desktop user.

```fish
# 1) Stop services that re-apply policy
systemctl --user disable --now audio-precedence-watch.service
systemctl --user stop filter-chain.service
systemctl --user disable filter-chain.service

# 2) Remove EQ link
rm -f ~/.config/pipewire/filter-chain.conf.d/10-audio-eq.conf

# 3) Restore WirePlumber conf.d from apply backup (pick newest timestamp)
#    Example — list first:
ls -d ~/.config/wireplumber/wireplumber.conf.d.bak.chg007.*
#    Then restore (replace TIMESTAMP):
set TS TIMESTAMP
mv ~/.config/wireplumber/wireplumber.conf.d ~/.config/wireplumber/wireplumber.conf.d.pre-backout
cp -a ~/.config/wireplumber/wireplumber.conf.d.bak.chg007.$TS ~/.config/wireplumber/wireplumber.conf.d

#    Or delete only CHG-007 files if you had no bak:
# rm -f ~/.config/wireplumber/wireplumber.conf.d/50-device-precedence.conf
# rm -f ~/.config/wireplumber/wireplumber.conf.d/52-stream-music-eq.conf

# 4) Restore audio-eq tree if desired
ls -d ~/.config/audio-eq.bak.chg007.*
# mv ~/.config/audio-eq ~/.config/audio-eq.pre-backout
# cp -a ~/.config/audio-eq.bak.chg007.$TS ~/.config/audio-eq

# 5) Remove helpers + unit
rm -f ~/.local/bin/audio-precedence-follow ~/.local/bin/audio-precedence-watch
rm -f ~/.config/systemd/user/audio-precedence-watch.service
rm -f ~/.config/systemd/user/default.target.wants/audio-precedence-watch.service
systemctl --user daemon-reload

# 6) Optional: restore pre-CHG-007 audio-eq binary
# cp -a ~/.local/bin/audio-eq.bak.chg007 ~/.local/bin/audio-eq

# 7) Optional: restore WP profile state that had sof_sdw=off
# cp -a ~/.local/state/wireplumber/default-profile.bak.chg007.$TS \
#       ~/.local/state/wireplumber/default-profile

# 8) Clear EQ as configured default
# Edit or truncate ~/.local/state/wireplumber/default-nodes so it no longer
# sets default.configured.audio.sink=effect_input.eq

# 9) Restart session audio
systemctl --user restart wireplumber.service
sleep 1
pactl set-default-sink bluez_output.F4_B6_2D_75_CE_92.1   # if P30i connected
# or: pactl set-default-sink <lenovo-or-builtin-sink-name>
```

### Backout verification

```fish
systemctl --user is-active audio-precedence-watch.service   # expect: inactive
systemctl --user is-active filter-chain.service             # expect: inactive (full backout)
test ! -e ~/.config/wireplumber/wireplumber.conf.d/50-device-precedence.conf; and echo "precedence gone"
pactl get-default-sink                                      # expect: hardware, not effect_input.eq
wpctl status
# Play Spotify — should hit P30i (or Lenovo) without EQ Rock filter
```

### Backup locations created by apply

| Path | Contents |
|------|----------|
| `~/.config/wireplumber/wireplumber.conf.d.bak.chg007.<TS>` | Pre-change WP drop-ins |
| `~/.config/audio-eq.bak.chg007.<TS>` | Pre-change EQ presets/state |
| `~/.config/pipewire/filter-chain.conf.d.bak.chg007.<TS>` | Pre-change filter-chain links |
| `~/.local/state/wireplumber/default-profile.bak.chg007.<TS>` | Profile pins (incl. sof_sdw=off) |
| `~/.local/bin/audio-eq.bak.chg007` | Pre-patch `audio-eq` binary |

Backout writes `*.pre-backout.<TS>` next to paths it replaces.

### Re-apply after backout

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-apply.sh
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg007-verify.fish
```

---

## Verify (post-apply)

```fish
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg007-verify.fish
~/.local/bin/audio-precedence-follow --print
pw-link -l | rg 'eq|spotify|bluez'
```

Expected healthy path with P30i connected:

```
Spotify → effect_input.eq (Rock) → bluez_output.…P30i
default source → Lenovo USB-C mic (A2DP has no capture)
```
