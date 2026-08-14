#!/usr/bin/env fish
# CHG-012 verify — Island Enterprise Browser is installed and launchable

function ok
    printf '  OK    %s\n' $argv
end
function fail
    printf '  FAIL  %s\n' $argv
    set -g failed 1
end

set -g failed 0
echo 'CHG-012 Island Enterprise Browser'

if pacman -Q island-browser-stable >/dev/null 2>&1
    ok (pacman -Q island-browser-stable)
else
    fail 'pacman: island-browser-stable not installed'
end

if test -x /usr/bin/island-browser-stable
    ok '/usr/bin/island-browser-stable'
else
    fail 'missing /usr/bin/island-browser-stable'
end

if test -x /opt/island/island-browser/Island
    ok '/opt/island/island-browser/Island'
else
    fail 'missing /opt/island/island-browser/Island'
end

if test -u /opt/island/island-browser/chrome-sandbox
    ok 'chrome-sandbox is setuid'
else
    fail 'chrome-sandbox is not setuid (sandbox may fall back to userns)'
end

if test -f /usr/share/applications/island-browser.desktop
    ok 'island-browser.desktop'
else
    fail 'missing island-browser.desktop'
end

if test -f ~/.config/island-browser-flags.conf
    if grep -q -- '--ozone-platform=wayland' ~/.config/island-browser-flags.conf
        ok 'island-browser-flags.conf has Wayland ozone'
    else
        fail 'island-browser-flags.conf missing --ozone-platform=wayland'
    end
else
    fail 'missing ~/.config/island-browser-flags.conf'
end

if test -f ~/.config/hypr/hyprland.conf
    if grep -q 'CHG-012 Island' ~/.config/hypr/hyprland.conf
        ok 'hyprland.conf has CHG-012 windowrule'
    else
        fail 'hyprland.conf missing CHG-012 windowrule'
    end
end

set default_browser (xdg-settings get default-web-browser 2>/dev/null)
if test "$default_browser" != island-browser.desktop -a "$default_browser" != org.island.Island.desktop
    ok "default browser unchanged ($default_browser)"
else
    fail "default browser was switched to Island ($default_browser)"
end

if command -q island-browser-stable
    # --version is enough; do not launch a window
    set ver (island-browser-stable --version 2>/dev/null | string collect)
    if test -n "$ver"
        ok "version: $ver"
    else
        fail 'island-browser-stable --version produced no output'
    end
end

echo
if test $failed -eq 1
    echo 'CHG-012 verify FAILED'
    exit 1
end
echo 'CHG-012 verify OK'
exit 0
