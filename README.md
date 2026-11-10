# Omarchy

This repository is the control for an agentic bare-metal install of [Omarchy](https://omarchy.org). A new laptop or image, about every six months, is a new generation. The agent reads the current release notes, applies the outcomes that must hold, and leaves a dated record of how that generation got there. The record replaces a golden image.

User space only: `~/.config/**` and this repo. The distro tree under `~/.local/share/omarchy/` is left alone.

The Outcomes Tracker is the catalog. Everything under it is history in service of those outcomes: what changed, what the generation learned, and what the next image inherits. A problem is an opportunity to improve the control. The dated row is that improvement, written down while it is still fresh.

## How a generation is bootstrapped

1. Read the release notes for the Omarchy version on the machine. A six-month jump moves the window manager, the terminal, the boot menu, and the installer. An older procedure is evidence. It is not a command.
2. Run `fish scripts/chg020-status.fish`. `OK` is an outcome that already holds. `SKIP` is hardware this machine does not have. `GAP` is the work left. `FAIL` is an outcome that used to hold and is ready for a fresh look.
3. Meet each gap with a path written for this disk, this audio device, and this config language. Record the path as the next change.
4. Privileged steps run in a terminal the operator can see. The operator approves them. The agent does not hold those secrets, and it does not commit or push.
5. When a step can be classified, a small analyzer does that in the same session and continues. The field generation's data volume is the example below.

Git stays with the operator: stage, sign, push. A signing denial is respected.

## Generations

Roles, not machine names. The same outcomes, a new path each time.

- **2026-07-05 · Desk and Dock.** First ledger. A desk tower and a docked laptop. Hyprland still used `monitors.conf`. Alacritty was the terminal. Starship was the stock prompt. Projects moved onto their own encrypted volume.
- **2026-08-05 · Dock.** The docked desk matured. The center panel changed. The laptop audio map was corrected. A wired headset was tried, then kept off the automatic failover list.
- **2026-08-14 – 2026-09-09 · Dock.** Work browser, snapshot policy, USB-C power, three-tier audio. Last dock as-built is 2026-09-09.
- **2026-11-09 – 2026-11-10 · Field.** An undocked laptop on older hardware and Omarchy 4.5. Hyprland is Lua. Super+Return is Foot. Audio is standard analog. One encrypted root, sized into an OS volume and a project volume during this generation. Same outcomes. A different path.

## Rules

| | |
|---|---|
| Kit once `/data` exists | `/data/Development/Projects/socfoundry/omarchy/` |
| Record id | Session *N* is `CHG-00N`. No gaps. **015** is reserved for project sync. |
| Next free | **CHG-023** |
| Data partition | 60% of that machine's disk, strictly over half. The OS keeps the rest. |
| Backup | `*.bak.chg00N.<YYYYMMDD-HHMMSS>` before every edit |
| Git | The operator stages, signs, and pushes. |

| Surface | Path |
|---------|------|
| Hyprland (4.5) | `~/.config/hypr/*.lua` |
| Hyprland (2026-07) | `~/.config/hypr/monitors.conf` · `bindings.conf` |
| Foot | `~/.config/foot/foot.ini` |
| Alacritty | `~/.config/alacritty/alacritty.toml` |
| fish / Tide | `~/.config/fish/` |
| WirePlumber / EQ | `~/.config/wireplumber/` · `~/.config/audio-eq/` |
| Scripts | `scripts/chg00N-*` |
| Notes | `docs/chg00N-*.md` |

## Outcomes Tracker

Checked on the field laptop the morning of 2026-11-10, before the volume: 20 OK, 4 skip, 1 gap, 0 fail. The gap was the project volume. That gap closed the same morning.

| Outcome | Where it holds | This generation |
|---------|----------------|-----------------|
| [Displays](#displays) | Docked desk has a named layout. Field keeps the internal panel | Desk layout stays on the desk |
| [Shell](#shell) | fish + Tide v6, black path text | Login shell is fish |
| [Terminal startup](#terminal-startup) | A one-shot snapshot, then fish, landing in Projects | Repo script, Foot on 4.5 |
| [Projects volume](#projects-volume) | Encrypted XFS at `/data`, home path is a symlink | Field volume is mounted. About 287 GiB. Next boot confirms the unlock |
| [Project sync](#project-sync) | One folder, LAN, no server | Reviewed and held until the project path is `/data` |
| [Snapshots](#snapshots) | One snapshot before pacman, keep 2, boot menu matches | Holds, including the 4.5 menu cap |
| [Audio](#audio) | Headset, then the laptop, through a Rock EQ | Field falls through to analog. The dock map stays on the dock |
| [Screenshots](#screenshots) | On the data volume once it exists | Field shots now follow `/data` |
| [Work browser](#work-browser) | Work browser installed, Chrome stays the default | Field waits on the vendor package |
| [USB power](#usb-power) | Each hub on its own supply | Dock wiring. Not this laptop |
| [Generations](#generations) | How a whole machine is brought up | The next image starts at the status script |

---

## Changelog

| Applied | CHG | Title | Where | Status | Risk |
|---------|-----|-------|-------|--------|------|
| 2026-07-05 | 001 | Desk layout | Desk | Applied | Low |
| 2026-07-06 | 002 | A prompt worth looking at | Desk · Dock | Applied | Low |
| 2026-07-06 | 003 | Terminal startup snapshot | both | Applied | Low |
| 2026-07-06 / 07-09 | 004 | Projects on their own disk | Desk · Dock | Applied | **High** |
| 2026-07-08 | 005 | Readable paths | both | Applied | Low |
| 2026-07-08 | 006 | Land in Projects | both | Applied | Low |
| 2026-07-19 | 007 | Audio precedence | Dock | Applied | Med |
| 2026-07-29 | 008 | Screenshots on the data volume | Dock | Applied | Low |
| 2026-08-05 | 009 | Center panel | Dock | Applied | Low |
| 2026-08-05 / 09-09 | 010 | Laptop audio map | Dock | Applied | Med |
| 2026-08-05 | 011 | Panel mode matches the dock | Dock | Applied | Low |
| 2026-08-14 | 012 | Work browser package | Dock | Applied | Med |
| 2026-08-14 | 013 | Work browser chords | Dock | Applied | Low |
| 2026-08-27 | 014 | Snapshots: pre-pacman, keep 2 | Dock | Applied | **High** |
| 2026-09-08 | 016 | USB-C power recovered | Dock | Applied | Low |
| 2026-09-09 | 017 | Three-tier audio | Dock | Applied | Med |
| 2026-09-09 | 018 | Hub wiring as-built | Dock | Applied | Low |
| 2026-11-10 | 019 | Field bring-up | Field | Applied | Med |
| 2026-11-10 | 020 | Provisioning control | Field | Applied | Low |
| 2026-11-10 | 021 | Outcome catalog | repo | Applied | Low |
| 2026-11-10 | 022 | Data volume from this disk | Field | Applied on the live session | **High** |

015 is reserved for project sync. It is not skipped. It waits until the project path is the data volume and a boot has confirmed the mount.

---

# Displays

A docked desk matches the panels on the desk. An undocked laptop keeps the internal panel. A layout belongs to the machine that has those panels.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-05 | Desk | Three 1080p panels, left to right, scale 1 | Named the outputs and set the offsets. The stock "preferred, auto" line and a doubled UI scale were fighting the desk. |
| 2026-08-05 | Dock | Center panel became a wider QHD display | Matched panels by their identity, not by the port number the dock assigns this week. Recomputed the row. Primary moved to the center. |
| 2026-08-05 | Dock | Refresh follows the mode the dock publishes | The advertised rate and the mode on this dock path were different. Driving the published mode keeps the picture through sleep. |
| 2026-11-09 | Field | Omarchy 4.5 configures displays in Lua | The internal panel stays stock. The desk files stay on the desk. |

# Shell

The login shell is fish. Tide v6 draws a Rainbow prompt with black path text. Bash and Starship stay installed for anything that still expects them.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-06 | Desk · Dock | Long sessions needed a prompt that shows the path, the clock, and when a command finishes | Fisher, Tide v6, the `done` notifier, Rainbow, two lines, a 24-hour clock. Login shell switched to fish. |
| 2026-07-08 | both | Path text on the Rainbow prompt was hard to read | Path colors set to black. One change, every later machine inherits it. |
| 2026-11-10 | Field | Omarchy 4.5 does not ship fish. Privileged install needs an operator terminal | The operator approved the install in a visible window. Fish 4.9.3, Tide pinned at v6 so the July flags still apply, path text black. New terminals pick it up immediately. |

# Terminal startup

Super+Return prints a one-shot picture of the machine, then an interactive fish. A new terminal starts in Projects. A terminal opened from a directory the operator is already in stays there.

On 4.5 the terminal is Foot, and the script lives in this repo (`bin/omarchy-term-login`). The data volume wins when it is mounted. Otherwise the home project tree is the landing spot.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-06 | both | Every new window needed a snapshot without repeating it inside the same window | The terminal starts fish, prints the snapshot, then replaces itself with an interactive fish. |
| 2026-07-08 | both | After the data volume, new terminals still opened at home | The startup changes to the project tree before the interactive shell. |
| 2026-11-10 | Field | Foot, and a working directory inherited from the previous terminal | The wrapper changes directory only when the start location is home or the filesystem root. The script is in the repo, so the next image does not depend on a file that exists only on one laptop. |

# Projects volume

The OS and the project tree are different encrypted volumes. Reinstalling the OS leaves Projects in place. `~/Development/Projects` is a symlink to `/data/Development/Projects`.

The size is a rule, not a constant from the first laptop. The data partition is 60% of the disk in the machine, aligned so it stays strictly over half. The OS keeps the rest, with room above what is already used and a floor so the system volume cannot be starved. On the field laptop that is about 287 GiB for projects and a 174 GiB OS filesystem inside a 179 GiB encrypted mapping. The first generation's fixed end-of-partition figure stays in the July record. It is not the formula.

**Field, 2026-11-10.** The volume is mounted. Projects and screenshots point at it. The previous project tree is kept beside the symlink until a reboot has shown the unlock and the automount. That reboot is the acceptance test. The live session already passed its own verify.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-06 | Desk | The installer ships one encrypted root. Projects had to outlive a reinstall | Live shrink of the OS volume, then a second encrypted XFS volume. Home path becomes a symlink. |
| 2026-07-09 | Dock | Same outcome, a smaller OS budget than the tower | The July scripts, with sizes taken from that disk. |
| 2026-11-10 | Field | A third disk size, Omarchy 4.5, and a live encrypted root that had to stay bootable the whole time | The section below. |

### Finishing the field volume

The field disk is a single NVMe of about 477 GiB. The installer had already put the whole OS in one encrypted btrfs volume: boot, root, home, logs, and the package cache as subvolumes of that one filesystem. The outcome required a second encrypted volume of more than half the disk, with the machine left running the entire time.

The safe order is the whole method. Nothing later in the list runs until the step before it has landed.

1. Shrink the filesystem first. The swap file on that filesystem is turned off for the resize and put back after. zram stays. The field filesystem moved to 174 GiB at 07:35 and the machine kept running. The encrypted mapping was still the installer's size, so the partition table was not touched. That gap is a bootable state on purpose.
2. Read the volume header before choosing a size. Omarchy 4.5 formats new installs with 4096-byte encryption sectors. The resize is specified so the result lands on that alignment. The volume key stays with the running mapping, which is why the shrink is an operator step in a visible terminal. A flag that would drop the key is refused by the tool. That refusal is correct: the machine is still using the volume.
3. Shrink the encrypted mapping only after that check, and only while the operator is at the keyboard. If the mapping is still larger than the target, stop. The partition is not moved.
4. Then, and only then, move the partition boundary, create the data partition, format it, open it, mount it, and point the home path at the new tree. The old tree stays until the next boot looks right.

### What the shrink taught the control

The morning of 2026-11-10 was a loop of privileged windows, and the loop was the lesson. Each window was the same plan. Each one returned before the encrypted mapping moved, with the filesystem already at 174 GiB and the partition table untouched. Repeating the window showed that the next generation needs one shell that can classify a result and continue. That is the analyzer.

| When | What we learned | What the next generation inherits |
|------|-----------------|-----------------------------------|
| 07:32 | The mount table prints the root as a path plus a subvolume suffix. That string is not a device node. A pipeline that stops on the first error ends before it can say why, which is why a device query can exit 32 with an empty explanation. | Find the partition from the device-mapper slave. Log the reason in the same step. |
| 07:35 | The filesystem can move to 174 GiB, with the swap file off only for that resize, while the encrypted mapping stays at the installer's size. | A bootable gap is a feature. The partition waits until the mapping has actually shrunk. |
| 07:39 – 08:28 | An empty trace can mean the step ran and could not write. On this kernel, root cannot append to a file the desktop user just created in `/tmp`. | Root logs live in the home directory. The script creates them. |
| Through 09:51 | A privileged prompt lasts five minutes by default. A window opened between sittings closes on that timer, and the next sitting starts from the top. | A high-risk sitting keeps the prompt valid for an hour, so one session can finish. |
| 10:30 | Classification belongs in the same root shell as the work. An operator at the keyboard, a result the function can name, and a handoff only after the mapping matches the target. | `scripts/chg022-heal.sh`. Confirm the volume, shrink the mapping to 179 GiB, then partition, format, mount, point the project path and the screenshots, and verify. The partition does not move unless the mapping shrunk. |

The same sitting also learned to write the operator's prompt straight to the terminal. A pipe holds a line that has no newline, so the person at the keyboard never sees it. And if the image did not ship the format tools, that sitting installs them and then formats.

The multi-hour lesson closed in a few minutes. The window exited clean. `/data` was mounted at 10:30.

Measured on the field laptop after that window. Sizes are the live volumes.

| Layer | Result |
|-------|--------|
| Disk | one NVMe, about 477 GiB |
| Boot | 2 GiB, about 140 MiB used |
| OS filesystem | 174 GiB btrfs, about 25 GiB used, about 149 GiB free. Subvolumes for root, home, logs, and the package cache |
| Encrypted OS mapping | sized to 179 GiB. 4096-byte sectors, key held with the running mapping |
| OS partition | about 188 GiB, ending at 190 GiB |
| Project volume | the rest of the disk, about 287 GiB, which is 60% of this disk. LUKS + XFS, mounted at `/data`. About 282 GiB free. The few gigabytes in use are filesystem metadata |
| Home path | `~/Development/Projects` is a symlink to `/data/Development/Projects`, set at 10:30 |
| Previous tree | kept beside the symlink until the reboot acceptance test |
| Screenshots | home path follows the project tree on `/data` |

A container does not get this partition sequence. If the root is not an encrypted mapping, the generation is given a data volume that is already over half of its disk.

Dated procedures: `scripts/chg004-*` for the first generation, `scripts/chg022-data-volume.sh` and `scripts/chg022-heal.sh` for the field generation. High risk. The reverse of a finished data volume is a restore from backup media, not a casual delete.

# Project sync

The project tree is the same work on every machine that has joined. Sync is LAN-only. There is no central server.

The July plan and the live configuration are both kept. The live file is the one a new machine joins. On 2026-11-10 the dock was reviewed over an administrative login. The package is installed. The service is stopped, which is the intended quiet state. The project folder points at `/data/Development/Projects` and is shared with the active peer. A retired machine is still in the device list and is not on that folder. The field laptop was not added.

That sequencing is the outcome. The share path has to be the data volume, and a boot has to prove the mount, before a second machine joins. 015 stays reserved for that join.

# Snapshots

Root is snapshotted once, immediately before pacman, and only the last two are kept. The boot menu shows the same two. Hourly timeline snapshots stay off.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-08-27 | Dock | A full timeline is a lesson in copy-on-write. Hundreds of snapshots filled the volume, and ordinary disk tools do not show that use. A quota limit does nothing when quotas are off. A delete that names a missing snapshot stops the whole batch | A pre-pacman hook, keep two, timeline off, cleanup on. A post-update hook puts the limit back if an Omarchy update restores a higher number. The rest were pruned. The next image starts from that policy. |
| 2026-11-10 | Field | Omarchy 4.5 caps the boot menu from a drop-in, and the main defaults file overrides that drop-in. The July edit replaced a key that was not in the file yet. A check that could not read the boot menu reported zero entries as a pass | Append the key when it is absent. Sync the menu. The status check treats an unreadable menu as skip, and reads the defaults file the account is allowed to read. The menu shows two snapshot entries. |

On 4.5 the boot menu also waits about a second and then boots. Holding a key at startup stops on the menu when a snapshot is the point. A timeout the operator sets in the menu file is left alone by updates.

# Audio

Playback prefers the headset the operator is wearing, then the laptop. Music and the browser run through a Rock EQ that follows whichever device won.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-19 | Dock | Bluetooth, USB, and the laptop all wanted to be the default | A fixed rank: headset, then the USB-C headset, then the built-in speakers, camera last. The EQ is the default sink and is reattached when the hardware changes. |
| 2026-08-05 | Dock | The headphone jack and the speakers are the same card, and the jack had been labeled as the speakers | The map names the jack and the speakers separately. |
| 2026-09-09 | Dock | Unplugging USB-C landed on the jack, because the jack still looked present at the desk | The jack stays mapped and leaves the automatic list. Unplug USB-C and the laptop speakers take over. |
| 2026-11-09 | Field | This laptop has a plain analog device. The dock map names cards this laptop does not have | The same rank. When the dock card is absent, playback uses the analog output. A status print says the jack is absent. |

# Screenshots

Shots are easy to take, and they live on the project volume once that volume exists, so they do not fill the OS disk.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-07-29 | Dock | Shots were landing on the OS volume. The desk keyboard has no Print key | `~/Pictures/Screenshots` became a symlink onto the data volume. Super+Shift+S takes the shot. |
| 2026-11-09 | Field | No data volume yet. Super+Shift+S was already in use. Omarchy 4.5 reads a new screenshot variable and still honors the old one | Both variables pointed at `~/Pictures/Screenshots`. Print Screen already captured. The existing chord was left as it was. |
| 2026-11-10 | Field | The data volume came up | Shots moved with it. The home path is a symlink onto the project tree. |

# Work browser

The work browser is an extra. Chrome stays the default.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-08-14 | Dock | The vendor ships a Debian package. Omarchy is Arch | A pacman package wrapped around that archive, Wayland flags, and no claim on the default browser. |
| 2026-08-14 | Dock | The package had no desk chord, and the Chrome chord had to stay | A launch-or-focus chord and an incognito chord that do not take Chrome's key. |
| 2026-11-09 | Field | The package is not in this kit, and 4.5 binds keys in Lua | Skipped cleanly. The outcome returns when the package is in the kit. |

# USB power

A hub that loses power takes the headset and the camera with it. Each hub has its own supply. Hubs are not daisy-chained for power.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-09-08 | Dock | A new hub reset every couple of seconds for about twenty minutes. No disk errors. Two new hubs were drawing from the bus, and another hub was chained behind both | Each hub got its own supply. The chained hub came off that run. The resets stopped. |
| 2026-09-09 | Dock | One device on the chain still needed more power than the hub should give, and an unused network port on a hub was an easy mistake | The standing map names what belongs on the hub. The heavy device waits for its own supply. |
| 2026-11-09 | Field | This laptop does not carry that dock | Skipped. The map stays with the dock generation. |

# Generations

A generation is one machine, or one image, brought up against the tracker, plus the process changes that came out of the work.

| When | Where | What changed | How it was finished |
|------|-------|--------------|---------------------|
| 2026-11-10 | Field | Bring an undocked 4.5 laptop up to the tracker without copying the dock | Fish, Tide, the terminal wrapper, screenshots, audio rank, and the snapshot cap. Desk monitors, dock audio map, dock USB, and the work browser were left for the machines that have that hardware. |
| 2026-11-10 | Repo | The repo has to be the control an agent can run, not a diary of one laptop | `scripts/chg020-status.fish` is the gate. Outcomes stay. Dated procedures stay under them. Release notes are read before a replay. |
| 2026-11-10 | Repo | The catalog moved in front of the dated procedures | This file. The tracker is first. Each outcome carries its own dated table. The next image starts from the results that must hold. |
| 2026-11-10 | Field | The project volume, on a disk the July sizes do not describe | [Projects volume](#projects-volume). |

## Roadmap

| ID | Next |
|----|------|
| **015** | Join project sync after a boot has shown `/data` mounting on its own. The live mesh, not the July roster, is the source. |
| **Boot acceptance** | Reboot the field laptop when the operator wants the proof. The live session already has the volume, the symlink, and a clean verify. |
| **Next image** | A generation bullet, the status script, then rows for whatever that Omarchy release moved. |

<sub>Tracker current through the field generation · 2026-11-10 · volume mounted · next free change **023**</sub>
