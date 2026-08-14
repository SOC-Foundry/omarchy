#!/usr/bin/env fish
# CHG-013 verify — Island desk setup (binds + default browser untouched)
function ok
    printf '  OK    %s\n' $argv
end
function fail
    printf '  FAIL  %s\n' $argv
    set -g failed 1
end

set -g failed 0
echo 'CHG-013 Island setup'

if not command -q island-browser-stable
    fail 'island-browser-stable missing (CHG-012)'
else
    ok 'island-browser-stable on PATH'
end

if grep -q 'SUPER SHIFT, I, Island' ~/.config/hypr/bindings.conf
    ok 'Super+Shift+I → Island'
else
    fail 'missing Super+Shift+I bind'
end

if grep -q 'SUPER SHIFT ALT, I, Island' ~/.config/hypr/bindings.conf
    ok 'Super+Shift+Alt+I → Island incognito'
else
    fail 'missing Super+Shift+Alt+I bind'
end

set default_browser (xdg-settings get default-web-browser 2>/dev/null)
if test "$default_browser" = google-chrome.desktop
    ok "xdg default still Chrome ($default_browser)"
else
    fail "xdg default changed ($default_browser)"
end

set class (hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class|test("island";"i")) | .class' | head -1)
if test -n "$class"
    ok "live Island window class=$class"
else
    ok 'Island not open (class expected: island-browser)'
end

if command -q hyprctl
    set errs (hyprctl configerrors 2>/dev/null | string collect)
    if test -z "$errs" -o "$errs" = "ok"
        ok 'hyprctl configerrors clean'
    else
        fail "hyprctl configerrors: $errs"
    end
end

echo
if test $failed -eq 1
    echo 'CHG-013 verify FAILED'
    exit 1
end
echo 'CHG-013 verify OK'
exit 0
