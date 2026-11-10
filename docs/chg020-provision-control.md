# CHG-020 — Provisioning control

The README is organized by outcome. This note is the generation-2 working log: what `o7400` forced us to change, and the false signals to stop trusting.

`o7400` is the second generation of this repo. `83te` (Yoga, docked, first Omarchy PC, ledger from 2026-07) is the first. The OS on `o7400` is Omarchy 4.5, about six months newer. The hardware is an undocked Latitude 7400. The Execute blocks under each outcome are what worked on that date. They are not the procedure for the next machine.

The goal is to drop a golden image. A bare-metal Omarchy install should reach the same outcomes by an agent applying this repo. The path is allowed to change. The outcome is not.

## How to read a CHG

| Piece | Lives | Changes when |
|---|---|---|
| **Objective** | The outcome. What must be true. | The operator wants something new. |
| **Challenge** | Which host, and what made the obvious path fail. | Never. It is the record. |
| **Execute** | The commands that worked that day. | Do not edit history. Write the next CHG. |

Replay Execute only when the hostname class and the Omarchy generation match the header. If the files named in Execute are gone (`bindings.conf` vs `bindings.lua`, Alacritty vs Foot), that CHG's path has expired. Meet the Objective another way and record it.

Skip a CHG whose Challenge names hardware this machine does not have. On `o7400` that is 001, 009, 011 (monitors), 010 (Yoga sof map), 016 and 018 (Yoga USB hubs).

## What `o7400` taught us

Replaying the ledger literally would have missed the outcome. The table is what this generation learned instead.

| Outcome | Generation-1 path | Path that worked on Omarchy 4.5 / `o7400` |
|---|---|---|
| Fish login + Tide v6 Rainbow, black path text | `yay fisher`, `chsh`, Alacritty | `pacman -S fish` in a real terminal. Fisher bootstrap. `ilancosman/tide@v6`. Foot is Super+Return. |
| New terminal prints a snapshot and lands in Projects | `alacritty.toml` `shell -c`, cwd `/data/Development/Projects` | `bin/omarchy-term-login`. Prefer `/data/...` when that volume exists, else `~/Development/Projects`. Keep a cwd inherited from another terminal. |
| Screenshots off the OS disk, reachable without a Print key | `/data/.../ss` and Super+Shift+S | Print Screen already captures. Super+Shift+S is Google Maps here. Set both `OMARCHY_SCREENSHOT_DIR` and `OMASNAP_SCREENSHOT_DIR`. Once `/data` exists, both point at the project tree and `~/Pictures/Screenshots` is a symlink there. On this host that landed 2026-11-10 10:30. |
| Headset, then laptop, plus Rock EQ for music | Yoga sof-soundwire PCM map, P30i MAC, Lenovo USB-C | Same WirePlumber files. Node names do not match HDA Analog Stereo, so they no-op. `audio-precedence-follow` falls through to the analog sink and glues the EQ to it. Do not re-run `chg010-apply.sh`. |
| Snapper: one snapshot before pacman, keep 2, boot menu matches | `sed` an existing `MAX_SNAPSHOT_ENTRIES` in `/etc/default/limine` | Omarchy 4.5 ships `MAX_SNAPSHOT_ENTRIES=6` in `/etc/limine-entry-tool.d/omarchy-defaults.conf`. `/etc/default/limine` overrides drop-ins and had no key, so the sed did nothing. Append the key, reinstall the post-update hook, run `limine-snapper-sync`. |
| Projects survive an OS reinstall | Shrink live LUKS+btrfs, new LUKS+XFS `/data` | Sizing is 60% of the measured disk (`scripts/chg022-data-volume.sh`). On `o7400` the filesystem moved to 174 GiB at 2026-11-10 07:35. At 10:30 the operator-led analyzer (`scripts/chg022-heal.sh`) sized the mapping to 179 GiB and mounted `/data` (about 287 GiB, LUKS+XFS). Reboot is the acceptance test. `~/Development/Projects.bak.chg004` stays until that boot. |
| Island as the work browser | Vendor `.deb` in the kit, pacman package, Super+Shift+I | `.deb` is not in the kit. Outcome skipped. |
| Privileged steps from an agent | `sudo` in the agent shell | This session has no TTY and no polkit agent. `pkexec` hangs. A Foot window the operator can type into works. |

## False signals to stop trusting

- `scripts/chg014-verify.fish` used to count Limine snapshot entries as 0 when `/boot/limine.conf` was unreadable, and call that OK. It now skips that line. The cap that matters without root is `MAX_SNAPSHOT_ENTRIES=2` in `/etc/default/limine`. A root read of `/boot/limine.conf` is the real menu count.
- `audio-precedence-follow --print` used to report the 3.5 mm jack as `on` when the Yoga sof card does not exist. A missing card is `absent`. Sink choice was already ignoring that jack (CHG-017).
- `chg007-verify.fish` looks for sof node names and a P30i MAC. On HDA hardware a missing sof profile is not a failure of the outcome. Use `chg020-status.fish` for the cross-host check. Keep `chg007-verify.fish` for the Yoga card.

## Next bare-metal host

1. Install Omarchy. Do not copy `83te`'s home directory.
2. Clone this repo into `~/Development/Projects/socfoundry/omarchy` (or `/data/...` once that volume exists).
3. Run `fish scripts/chg020-status.fish`.
4. For each `FAIL` or `GAP`, read the outcome in the table above and the newest CHG that claims it. Adapt the path. Do not start at CHG-001 and walk forward.
5. Privileged installs (packages, snapper, Limine) go through a terminal the operator can type a password into.
6. Disk layout is a separate yes. Never as a side effect of "apply the repo".
7. Finish with `chg020-status.fish` again. `FAIL` must be 0. Record a CHG for what this host needed that the previous one did not.

## Still open on `o7400`

- Reboot, when the operator wants the proof. The live session already has `/data` mounted, the project symlink, and a clean verify. After that boot, the operator can remove `~/Development/Projects.bak.chg004`.
- Island, when a current `.deb` is in the kit.
- Syncthing (015) after that boot, and only when the operator asks. The dock was reviewed with the service left stopped. This laptop was not joined.
