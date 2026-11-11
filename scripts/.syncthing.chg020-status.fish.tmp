#!/usr/bin/env fish
# CHG-020 — does this host meet the control?
# OK holds. SKIP is not this host. GAP is wanted and not done. FAIL is broken.
# Exit 1 only when FAIL > 0. Gaps are printed and left for the next CHG.

set -l repo (path dirname (status dirname))
set -g n_ok 0
set -g n_skip 0
set -g n_gap 0
set -g n_fail 0

function ok
    set -g n_ok (math $n_ok + 1)
    printf '  OK    %s\n' "$argv"
end
function skip
    set -g n_skip (math $n_skip + 1)
    printf '  SKIP  %s\n' "$argv"
end
function gap
    set -g n_gap (math $n_gap + 1)
    printf '  GAP   %s\n' "$argv"
end
function bad
    set -g n_fail (math $n_fail + 1)
    printf '  FAIL  %s\n' "$argv"
end

set -l host (hostname -s)
set -l ver unknown
if test -r /etc/os-release
    set ver (string match -r 'VERSION_ID=.*' </etc/os-release | string replace 'VERSION_ID=' '' | string trim -c '"')
end
echo "CHG-020 control  host=$host  omarchy=$ver"
echo

echo "--- shell and terminal ---"
set -l shell (getent passwd $USER | string split ':')[7]
if test "$shell" = /usr/bin/fish
    ok "login shell is fish"
else
    bad "login shell is $shell (want /usr/bin/fish)"
end
if command -q fish
    ok "fish is installed"
else
    bad "fish is not installed"
end
if functions -q fisher; or test -f ~/.config/fish/functions/fisher.fish
    if fisher list 2>/dev/null | string match -q 'ilancosman/tide@v6'
        ok "Tide v6 installed"
    else
        bad "Tide v6 missing (fisher list)"
    end
    if fisher list 2>/dev/null | string match -q 'franciscolourenco/done'
        ok "done plugin installed"
    else
        gap "done plugin not installed"
    end
else
    bad "fisher is not installed"
end
set -l pwd_color (fish -c 'echo $tide_pwd_color_dirs' 2>/dev/null)
if test "$pwd_color" = black
    ok "Tide path text is black"
else
    gap "Tide path color is '$pwd_color' (want black)"
end

set -l login_link ~/.local/bin/omarchy-term-login
set -l login_src $repo/bin/omarchy-term-login
if test -x $login_src
    ok "repo owns bin/omarchy-term-login"
else
    bad "missing $login_src"
end
if test -L $login_link; and test (realpath $login_link) = (realpath $login_src)
    ok "~/.local/bin/omarchy-term-login -> repo"
else if test -x $login_link
    gap "term login is a private copy, not the repo file"
else
    bad "term login is not on PATH (~/.local/bin/omarchy-term-login)"
end
if test -f ~/.config/foot/foot.ini; and string match -qr omarchy-term-login < ~/.config/foot/foot.ini
    ok "Foot Super+Return uses omarchy-term-login"
else if test -f ~/.config/alacritty/alacritty.toml; and string match -qr omarchy-term-login < ~/.config/alacritty/alacritty.toml
    ok "Alacritty uses omarchy-term-login (Foot is not the launcher here)"
else
    bad "neither Foot nor Alacritty launches omarchy-term-login"
end

echo
echo "--- projects and screenshots ---"
if test -d /data/Development/Projects
    ok "/data/Development/Projects is mounted"
    if test -b /dev/mapper/data
        set -l data_b (lsblk -b -dn -o SIZE /dev/mapper/data 2>/dev/null | head -1)
        set -l part (lsblk -no PKNAME /dev/mapper/data 2>/dev/null | head -1)
        set -l disk (lsblk -no PKNAME /dev/$part 2>/dev/null | head -1)
        set -l disk_b (lsblk -b -dn -o SIZE /dev/$disk 2>/dev/null | head -1)
        if test -n "$data_b" -a -n "$disk_b"
            if test $data_b -gt (math -s0 "$disk_b / 2")
                ok "data volume is over half the disk"
            else
                bad "data volume is not over half the disk ($data_b of $disk_b)"
            end
        end
    end
    if test -L ~/Development/Projects
        set -l target (readlink -f ~/Development/Projects)
        if test "$target" = /data/Development/Projects
            ok "~/Development/Projects → /data/Development/Projects"
        else
            bad "~/Development/Projects symlink target is $target"
        end
    else
        bad "~/Development/Projects is not a symlink onto /data"
    end
else
    gap "/data volume is absent — run scripts/chg022-data-volume.sh from a terminal"
    if test -d ~/Development/Projects
        ok "~/Development/Projects exists on the OS volume"
    else
        bad "~/Development/Projects is missing"
    end
end
if test -d /data/Development/Projects/socfoundry/ss
    if test -L ~/Pictures/Screenshots
        set -l shot (readlink -f ~/Pictures/Screenshots)
        if test "$shot" = /data/Development/Projects/socfoundry/ss
            ok "screenshots → /data/Development/Projects/socfoundry/ss"
        else
            bad "screenshot symlink target is $shot"
        end
    else
        gap "screenshot dir is not a symlink onto /data"
    end
else if test -d ~/Pictures/Screenshots
    ok "screenshot directory exists"
else
    bad "~/Pictures/Screenshots is missing"
end
if test -f ~/.config/hypr/hyprland.lua; and string match -qr OMASNAP_SCREENSHOT_DIR < ~/.config/hypr/hyprland.lua
    ok "Hyprland sets OMASNAP_SCREENSHOT_DIR"
else
    gap "Hyprland has no OMASNAP_SCREENSHOT_DIR (Omarchy default ~/Pictures/Screenshots still applies)"
end

echo
echo "--- displays ---"
set -l monitors (hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys
try:
    ms=json.load(sys.stdin)
except Exception:
    print("0")
    raise SystemExit
print(len(ms))
for m in ms:
    print(m.get("name",""), m.get("description",""))' 2>/dev/null)
set -l nmon (echo $monitors | string split ' ')[1]
if test "$nmon" = 1
    skip "single monitor — desk layout (001/009/011) does not apply"
else if test -n "$nmon"
    gap "$nmon monitors connected — desk layout CHGs were written for 83te, review before applying"
else
    gap "could not read hyprctl monitors"
end

echo
echo "--- audio ---"
for u in wireplumber.service filter-chain.service audio-precedence-watch.service
    if test (systemctl --user is-active $u 2>/dev/null) = active
        ok "$u active"
    else
        bad "$u is not active"
    end
end
set -l sink (pactl get-default-sink 2>/dev/null)
if test "$sink" = effect_input.eq
    ok "default sink is Rock EQ"
else
    bad "default sink is $sink (want effect_input.eq)"
end
if test -x ~/.local/bin/audio-precedence-follow
    set -l hw (audio-precedence-follow --print 2>/dev/null | string match -r 'hardware_sink=.*' | string replace 'hardware_sink=' '')
    if test -n "$hw"; and test "$hw" != none
        ok "hardware sink resolves ($hw)"
    else
        bad "audio precedence did not resolve a hardware sink"
    end
else
    bad "audio-precedence-follow is not installed"
end

echo
echo "--- snapper and Limine ---"
if test -f /etc/pacman.d/hooks/05-snapper-pacman-pre.hook
    ok "pre-pacman snapper hook"
else
    bad "missing pre-pacman snapper hook"
end
set -l nlim (string match -r 'NUMBER_LIMIT=.*' </etc/snapper/configs/root 2>/dev/null | string replace -r '.*"([0-9]+)".*' '$1')
if test "$nlim" = 2
    ok "snapper NUMBER_LIMIT=2"
else
    bad "snapper NUMBER_LIMIT=$nlim (want 2)"
end
if test (systemctl is-enabled snapper-timeline.timer 2>/dev/null) = disabled
    ok "snapper timeline off"
else
    bad "snapper timeline is not disabled"
end
if string match -qr '^MAX_SNAPSHOT_ENTRIES=2$' < /etc/default/limine
    ok "Limine MAX_SNAPSHOT_ENTRIES=2"
else
    bad "Limine MAX_SNAPSHOT_ENTRIES is not 2 in /etc/default/limine"
end
if test -r /boot/limine.conf
    set -l entries (string match -r -a 'snapshots/[0-9]+' </boot/limine.conf | sort -u)
    if test (count $entries) -le 2
        ok "Limine menu snapshots: $entries"
    else
        bad "Limine menu has more than 2 snapshot entries: $entries"
    end
else
    skip "Limine menu count needs a readable /boot/limine.conf"
end

echo
echo "--- optional, host-specific ---"
if command -q island-browser-stable
    ok "Island browser is installed"
else
    skip "Island browser not installed (deb is not in the kit)"
end
if test "$host" = 83te
    skip "Yoga USB hub wiring is a desk check, not a file (016/018)"
else
    skip "Yoga USB hub notes do not apply on $host"
end

echo
echo "OK $n_ok  SKIP $n_skip  GAP $n_gap  FAIL $n_fail"
if test $n_fail -gt 0
    echo "CHG-020 control FAILED"
    exit 1
end
echo "CHG-020 control HOLDS (gaps are unfinished, not broken)"
exit 0
