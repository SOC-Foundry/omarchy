#!/usr/bin/env fish
# CHG-018 verify — second USB-C hub as-built (83te)
set -l fail 0
function ok; echo "  OK  $argv"; end
function bad; echo "  FAIL $argv"; set -g fail 1; end

echo "=== CHG-018 verify "(date -Is)" ==="

set -l ids (lsusb | string collect)
for pair in 05e3:0626 05e3:0610 0c45:636b 17ef:a05f 045e:02ea
    if string match -q "*$pair*" $ids
        ok "lsusb $pair"
    else
        bad "missing $pair"
    end
end

if test -e /dev/input/js0
    ok "js0 present"
else
    bad "no /dev/input/js0"
end
if test -e /dev/video4
    ok "/dev/video4 (USB camera)"
else
    bad "no /dev/video4"
end

set -l pc (journalctl -k --since '15 minutes ago' --no-pager | grep -c 'attempt power cycle')
if test "$pc" -eq 0
    ok "no USB power-cycle in last 15m"
else
    bad "power-cycle count last 15m: $pc"
end

echo
if test $fail -eq 0
    echo "=== RESULT: PASS ==="
    exit 0
end
echo "=== RESULT: FAIL ==="
exit 1
