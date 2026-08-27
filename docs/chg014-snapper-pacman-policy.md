# CHG-014 — Snapper: pre-pacman only, keep last 2

> `14` · **Applied** · 2026-08-27 · `83te` · **High**  
> Home: [Ch III · 014](../README.md#chg-014--snapper-pre-pacman-only-keep-last-2) · [log](../README.md#chg-log) · [register](../README.md#chg-register)  
> Same disk as [CHG-004](../README.md#chg-004--projects-on-their-own-disk) (`nvme0n1p2` 200 GiB btrfs root).

Host: Lenovo Yoga 7 (`83te`) · Omarchy on LUKS+btrfs `nvme0n1p2` (`/dev/mapper/root`, 200 GiB).  
`/` `@`, `/home` `@home`, `/var/log` `@log`, `/var/cache/pacman/pkg` `@pkg`.

---

## Summary

Omarchy’s native snapshot story is “a few numbered root snapshots so you can roll back a bad update.” On this machine that story never stuck. Stock Snapper **hourly timeline** snapshots ran with **cleanup disabled**, filled the 200 GiB OS volume to 100%, and hid ~70 GiB of copy-on-write exclusive data that `du` on `/` never showed.

Fix: snapshot **only before pacman**, keep the **last 2**, prune the rest, and re-apply the policy after `omarchy update` so a later distro migration does not reopen the hole.

| Before (2026-08-27 09:24) | After prune (09:38+) |
|---|---|
| 182 GiB used / **681 MiB** free (**100%**) | **100 GiB** used / **80 GiB** free (**56%**) |
| Snapper IDs up to **882** (~880 live) | **881** and **882** only |
| `snapper-timeline.timer` enabled | disabled |
| `snapper-cleanup.timer` disabled | enabled |
| `NUMBER_LIMIT=50`, `TIMELINE_CREATE=yes` | `NUMBER_LIMIT=2`, `TIMELINE_CREATE=no` |

---

## The native problem

### What Omarchy intends

Omarchy ships a short Snapper config and a pre-update helper. It does **not** ship `snap-pac`.

```1:8:/home/kthompson/.local/share/omarchy/default/snapper/root
# Omarchy snapshots root only for pre-update recovery — kept to 5, no timeline
SUBVOLUME="/"
FSTYPE="btrfs"

NUMBER_LIMIT="5"
NUMBER_LIMIT_IMPORTANT="5"

TIMELINE_CREATE="no"
```

Install (`limine-snapper.sh`) and migration `1776927490.sh` copy that file over `/etc/snapper/configs/root`, delete timeline snapshots, and run `snapper cleanup number`. `omarchy update` then calls `omarchy-snapshot create`, which takes one **numbered** snapshot of each Snapper config and runs `cleanup number`.

There is no pacman PreTransaction hook. Raw `pacman` / `yay` / `omarchy pkg` do not snapshot unless something else does.

Omarchy also **disables btrfs quotas**. Snapper’s `SPACE_LIMIT` / `FREE_LIMIT` only work with qgroups, so they cannot stop the disk filling even when those keys are set.

`snapper-cleanup.timer` is a systemd **preset: disabled**. Omarchy never enables it. `snapper-timeline.timer` is also preset-disabled, but on this host it was **enabled**.

### What was actually running on 83te

`/etc/snapper/configs/root` was the **stock** `snapper create-config` template, not Omarchy’s 8-line default:

| Key | Stock on 83te | Omarchy default | Effect |
|---|---|---|---|
| `TIMELINE_CREATE` | `yes` | `no` | Hourly snapshots |
| `NUMBER_LIMIT` | `50` | `5` | Keep up to 50 numbered snaps |
| Timeline hourly/daily/monthly/yearly | 10 / 10 / 10 / 10 | unset (treated as 0) | Long tail of hourly snaps |
| `QGROUP` | empty | empty | No space-aware cleanup |
| `NUMBER_MIN_AGE` | `3600` | unset | Cleanup skips anything < 1 h |

Timers:

```
snapper-timeline.timer   enabled    active     # created a snapshot every hour
snapper-cleanup.timer    disabled   inactive   # never pruned
snapper-boot.timer       disabled
```

Limine boot entries already pointed at snapshot **882**. From install (2026-07-04) to 2026-08-27 that is ~16 snapshots/day: hourly timeline plus whatever `omarchy-snapshot` / package work added.

### Why the disk looked “empty” until it was full

btrfs snapshots share unchanged extents. `du -x /` only sees the live subvolumes:

| Live tree | ~Size | Notes |
|---|---|---|
| `@` (`/usr`, `/opt`, `/var` minus log/pkg, `/swap`) | ~34 GiB | includes 16 GiB hibernation swapfile |
| `@home` | ~64 GiB | includes leftover `~/Projects.chg004.bak` (45 GiB, not this CHG) |
| `@pkg` | 13 GiB | pacman cache |
| `@log` | 179 MiB | journal |
| **Live total** | **~111 GiB** | |
| **btrfs used** | **181 GiB** | |
| **Snapshot exclusive** | **~70 GiB** | invisible to `du` |

`/.snapshots` is `0750 root:root`, so a normal user cannot even list them. `df` just says the filesystem is full.

---

## How it was fixed

Policy the operator asked for: **one snapshot before pacman, keep the last 2.**

1. **Create** a Snapper snapshot in a pacman `PreTransaction` hook (`type=single`, `cleanup=number`). Not `--type pre` — unpaired pre/post pairs get eaten by `EMPTY_PRE_POST_CLEANUP`.
2. **Immediately** `snapper cleanup number` so the cap is 2 without waiting for a timer.
3. **Stop creating** hourly/boot snapshots: `TIMELINE_CREATE=no`, disable `snapper-timeline.timer` and `snapper-boot.timer`.
4. **Enable** `snapper-cleanup.timer` as a safety net.
5. **Skip** the extra snapshot `omarchy update` takes via `omarchy-snapshot create`. That call is on `PATH`; `omarchy snapshot create` (the dispatcher) still hits `~/.local/share/omarchy/bin/omarchy-snapshot` and is left alone. Without the skip, one update would consume both slots (omarchy snapshot + pacman pre) and throw away the previous restore point.
6. **Re-apply** the Snapper keys after `omarchy update`. Migration `1776927490.sh` (and future cousins) `cp` Omarchy’s `NUMBER_LIMIT=5` file over `/etc/snapper/configs/root`. A `post-update.d` hook puts the cap back to 2 and keeps timeline off.
7. **Limine** `MAX_SNAPSHOT_ENTRIES=2` so the boot menu matches Snapper.
8. **Prune** the ~880 existing snapshots down to the two newest, then `limine-snapper-sync`.

Durable files (do not live in `~/.local/share/omarchy/`):

| Path | Role |
|---|---|
| `/etc/pacman.d/hooks/05-snapper-pacman-pre.hook` | alpm PreTransaction trigger |
| `/usr/local/sbin/snapper-pacman-pre` | create + `cleanup number` |
| `~/.local/bin/omarchy-snapshot` | skip `create`; restore still delegates |
| `~/.config/omarchy/hooks/post-update.d/snapper-pacman-policy` | re-apply cap/timers after `omarchy update` |
| `/etc/snapper/configs/root` | `NUMBER_LIMIT=2`, `TIMELINE_CREATE=no`, ages 0 |
| `/etc/default/limine` | `MAX_SNAPSHOT_ENTRIES=2` |

Skip a single transaction without disabling the hook:

```bash
sudo SNAPPER_SKIP=1 pacman -S some-pkg
```

---

## Remediation that actually ran (2026-08-27)

Two sudo passes in a floating Alacritty (fingerprint), because this agent has no TTY for `sudo`.

### Pass 1 — `install.sh`

Set the policy, install the hook, disable timeline, enable cleanup, try to delete 878 snapshots in batches of 40.

**Bug:** `snapper delete A B C` **aborts the whole invocation** if any ID is missing. Broken leftover metadata for snapshots **3, 4, 5, 6, 44** (`Snapshot.cc(read): snapshot check failed`) sat in the first batches, so those batches no-op’d. Later batches (IDs ≳ 81) did delete. Result: 77 snapshots left (mostly July timeline 7–82 plus 881/882), ~37 GiB freed, Limine warning `77 Snapper snapshots exceed configured MAX_SNAPSHOT_ENTRIES=2`.

### Pass 2 — `prune-remaining.sh`

Clear broken `/.snapshots/{6,44}`, then **delete one ID at a time**, keep **881** and **882**, `snapper modify --cleanup-algorithm number` so future `cleanup number` treats them as part of the cap of 2, `limine-snapper-sync`.

```
remaining:
  0   current
881   2026-08-27 08:50  cleanup=number  (was timeline)
882   2026-08-27 09:00  cleanup=number  (was timeline)
```

Used **115 GiB / 65 GiB free** immediately; btrfs cleaner then reclaimed further to **~100 GiB / 80 GiB free**.

---

## Scripts

Copies live in `scripts/chg014-files/` and are installed by `scripts/chg014-apply.sh`. Below is what ran.

### Pacman hook — `/etc/pacman.d/hooks/05-snapper-pacman-pre.hook`

```ini
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating snapper snapshot before pacman
When = PreTransaction
Depends = snapper
AbortOnFail = false
Exec = /usr/local/sbin/snapper-pacman-pre
```

### Hook body — `/usr/local/sbin/snapper-pacman-pre`

```bash
#!/bin/bash
# Create a numbered Snapper snapshot before a pacman transaction, then
# immediately drop everything except the last 2 numbered snapshots.
set -u

if [[ -n "${SNAPPER_SKIP:-}" || -n "${SNAP_PAC_SKIP:-}" ]]; then
  exit 0
fi

/usr/bin/snapper --no-dbus --config root create \
  --type single \
  --cleanup-algorithm number \
  --description "pacman" || true

/usr/bin/snapper --no-dbus --config root cleanup number || true

exit 0
```

### Policy apply (pass 1)

```bash
#!/bin/bash
# Apply: snapshots only before pacman, keep last 2, prune the rest.
set -euo pipefail

SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install -d /usr/local/sbin /etc/pacman.d/hooks
install -m 0755 "$SRC/snapper-pacman-pre" /usr/local/sbin/snapper-pacman-pre
install -m 0644 "$SRC/05-snapper-pacman-pre.hook" /etc/pacman.d/hooks/05-snapper-pacman-pre.hook

echo "==> Snapper policy: no timeline, keep 2 numbered snapshots"
snapper --no-dbus -c root set-config \
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

echo "==> Disable hourly/boot snapshot timers; enable cleanup"
systemctl disable --now snapper-timeline.timer
systemctl disable --now snapper-boot.timer || true
systemctl enable --now snapper-cleanup.timer

if [[ -f /etc/default/limine ]]; then
  sed -i 's/^MAX_SNAPSHOT_ENTRIES=.*/MAX_SNAPSHOT_ENTRIES=2/' /etc/default/limine
fi

# Batch delete of all-but-last-2 is in the original install.sh.
# Do not use batches if any snapshot ID is missing — use chg014-prune.sh.
```

### One-at-a-time prune (pass 2) — this is the one that finished the job

```bash
#!/bin/bash
# snapper delete aborts a whole batch if any ID is missing.
set -u

for n in 3 4 5 6 44; do
  if [[ -e /.snapshots/$n ]]; then
    btrfs subvolume delete -c /.snapshots/$n/snapshot 2>/dev/null || true
    rm -rf /.snapshots/$n
  fi
done

mapfile -t nums < <(snapper --no-dbus -c root list --columns number 2>/dev/null \
  | awk 'NR>2 && $1+0 == $1 && $1 != "0" {print $1}')

keep=("${nums[-2]}" "${nums[-1]}")
for n in "${nums[@]:0:${#nums[@]}-2}"; do
  snapper --no-dbus -c root delete "$n" || {
    btrfs subvolume delete -c /.snapshots/$n/snapshot 2>/dev/null || true
    rm -rf /.snapshots/$n
  }
done

snapper --no-dbus -c root modify --cleanup-algorithm number "${keep[@]}"
limine-snapper-sync
```

### `~/.local/bin/omarchy-snapshot` (PATH wrapper)

```bash
#!/bin/bash
set -euo pipefail
OMARCHY_SNAPSHOT="/home/kthompson/.local/share/omarchy/bin/omarchy-snapshot"
if [[ "${1:-}" == "create" ]]; then
  echo "Skipping extra snapshot (pacman pre-transaction hook keeps the last 2)"
  exit 0
fi
exec "$OMARCHY_SNAPSHOT" "$@"
```

### `~/.config/omarchy/hooks/post-update.d/snapper-pacman-policy`

Re-runs `snapper set-config` (limit 2, no timeline), disables timeline/boot timers, enables cleanup, sets `MAX_SNAPSHOT_ENTRIES=2`. Full file: `scripts/chg014-files/snapper-pacman-policy`.

---

## Apply / verify / backout (this repo)

```bash
cd /data/Development/Projects/socfoundry/omarchy
sudo bash scripts/chg014-apply.sh          # hook + Snapper keys + timers
sudo bash scripts/chg014-prune.sh          # only if leftovers remain; keep last 2
fish scripts/chg014-verify.fish
```

```bash
sudo bash scripts/chg014-backout.sh        # restore Omarchy-ish NUMBER_LIMIT=5, remove hook
# does not recreate the 880 deleted snapshots
```

---

## Checks after apply

```bash
systemctl is-enabled snapper-timeline.timer snapper-boot.timer snapper-cleanup.timer
# disabled / disabled / enabled

sudo snapper --no-dbus -c root get-config | grep -E 'NUMBER_LIMIT|TIMELINE_CREATE'
# NUMBER_LIMIT 2 · TIMELINE_CREATE no

sudo snapper --no-dbus -c root list
# current + two newest

grep -oE 'snapshots/[0-9]+' /boot/limine.conf | sort -u
# two IDs, matching snapper

df -h /
test -x /usr/local/sbin/snapper-pacman-pre
test -f /etc/pacman.d/hooks/05-snapper-pacman-pre.hook
omarchy-snapshot create   # should print skip, not create
```

---

## What this CHG did not do

- Did **not** delete `~/Projects.chg004.bak` (45 GiB Syncthing leftover from CHG-004; live tree is `/data/Development/Projects`).
- Did **not** trim `/var/cache/pacman/pkg` (13 GiB) or `~/.cache/yay`.
- Did **not** `btrfs filesystem resize max /` (~15 GiB device slack still unused).
- Did **not** edit `~/.local/share/omarchy/` (wrapper + post-update hook only).

---

## Why not `snap-pac`

`snap-pac` takes a **pre and a post** per transaction. With `NUMBER_LIMIT=2` that is one transaction’s pair, not two restore points. A single `type=single` snapshot per pacman run matches “prior to pacman, keep last 2.”
