#!/usr/bin/env fish
# CHG-004 post-setup verify (and optional cleanup) for 83te
# Usage:
#   sudo fish ~/Downloads/scripts/chg004-verify.fish
#   sudo fish ~/Downloads/scripts/chg004-verify.fish --cleanup   # delete btrfs .bak copies
#   sudo fish ~/Downloads/scripts/chg004-verify.fish --reboot

set -l do_cleanup 0
set -l do_reboot 0
for a in $argv
    switch $a
        case --cleanup
            set do_cleanup 1
        case --reboot
            set do_reboot 1
        case -h --help
            echo "Usage: sudo fish "(status filename)" [--cleanup] [--reboot]"
            exit 0
    end
end

if test (id -u) -ne 0
    echo "ERROR: run with sudo, e.g.:"
    echo "  sudo fish "(status filename)
    exit 1
end

set -l user kthompson
set -l home /home/$user
set -l fail 0

function ok
    echo "  OK  $argv"
end
function bad
    echo "  FAIL $argv"
    set -g fail 1
end

echo "=== CHG-004 verify "(date -Is)" ==="
echo

echo "--- block devices ---"
lsblk -f /dev/nvme0n1
echo

echo "--- mounts ---"
df -hT / /data /boot
echo

# Expected UUIDs from 83te apply (2026-07-09)
set -l expect_data_luks a830ae16-1d9c-4411-9892-f8e8de2ebd3c
set -l expect_data_fs 5e7b8d54-0931-475b-8163-1b057921d781

echo "--- crypttab ---"
if test -r /etc/crypttab
    cat /etc/crypttab
    if grep -qE "^data[[:space:]].*$expect_data_luks" /etc/crypttab
        ok "data LUKS UUID present"
    else if grep -qE '^data[[:space:]]' /etc/crypttab
        ok "data entry present (UUID differs from recorded — check manually)"
    else
        bad "no data line in crypttab"
    end
else
    bad "cannot read /etc/crypttab"
end
echo

echo "--- fstab /data ---"
if grep -qE "[[:space:]]/data[[:space:]]" /etc/fstab
    grep /data /etc/fstab
    if grep -q "$expect_data_fs" /etc/fstab
        ok "XFS UUID matches"
    else
        ok "fstab has /data (UUID check skipped/mismatch)"
    end
else
    bad "no /data in fstab"
end
echo

echo "--- live state ---"
if mountpoint -q /data
    ok "/data is mounted"
else
    bad "/data is NOT mounted"
end

if test -e /dev/mapper/data
    ok "mapper data open"
else
    bad "mapper data missing"
end

set -l p2_bytes (blockdev --getsize64 /dev/nvme0n1p2 2>/dev/null)
set -l p3_bytes (blockdev --getsize64 /dev/nvme0n1p3 2>/dev/null)
if test -n "$p2_bytes"
    # ~200 GiB = 214748364800
    if test $p2_bytes -gt 200000000000 -a $p2_bytes -lt 220000000000
        ok "p2 size ~200 GiB ($p2_bytes bytes)"
    else
        bad "p2 unexpected size: $p2_bytes"
    end
end
if test -n "$p3_bytes"
    ok "p3 size $p3_bytes bytes"
end

set -l proj $home/Development/Projects
if test -L $proj
    set -l target (readlink -f $proj)
    if test "$target" = /data/Development/Projects
        ok "Projects symlink → $target"
    else
        bad "Projects symlink points to $target"
    end
else
    bad "Projects is not a symlink at $proj"
end

if test -d /boot/EFI/Linux
    ls -la /boot/EFI/Linux/
    ok "UKI dir present"
end
echo

if test $do_cleanup -eq 1
    echo "--- cleanup btrfs safety copies ---"
    for d in $home/Projects.chg004.bak $home/Development/Projects.bak.chg004
        if test -e $d
            echo "Removing $d ..."
            rm -rf $d
            ok "removed $d"
        else
            ok "already gone: $d"
        end
    end
    df -hT /
    echo
else
    echo "--- bak copies (not deleted; pass --cleanup when ready) ---"
    for d in $home/Projects.chg004.bak $home/Development/Projects.bak.chg004
        if test -e $d
            du -sh $d
        end
    end
    echo
end

if test $fail -eq 0
    echo "=== RESULT: PASS ==="
else
    echo "=== RESULT: FAIL (see above) ==="
end

if test $do_reboot -eq 1
    echo "Rebooting in 3s..."
    sleep 3
    reboot
end

exit $fail
