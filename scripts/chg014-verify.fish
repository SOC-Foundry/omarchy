#!/usr/bin/env fish
# CHG-014 verify — pre-pacman snapshots, last 2, timeline off

function ok
    printf '  OK    %s\n' $argv
end
function fail
    printf '  FAIL  %s\n' $argv
    set -g failed 1
end

set -g failed 0
echo 'CHG-014 Snapper pre-pacman / keep 2'

if test -f /etc/pacman.d/hooks/05-snapper-pacman-pre.hook
    ok 'pacman hook 05-snapper-pacman-pre.hook'
else
    fail 'missing /etc/pacman.d/hooks/05-snapper-pacman-pre.hook'
end

if test -x /usr/local/sbin/snapper-pacman-pre
    ok '/usr/local/sbin/snapper-pacman-pre'
else
    fail 'missing /usr/local/sbin/snapper-pacman-pre'
end

if test -x $HOME/.local/bin/omarchy-snapshot
    ok '~/.local/bin/omarchy-snapshot wrapper'
else
    fail 'missing ~/.local/bin/omarchy-snapshot'
end

set hook $HOME/.config/omarchy/hooks/post-update.d/snapper-pacman-policy
if test -x $hook
    ok 'post-update hook snapper-pacman-policy'
else
    fail "missing $hook"
end

switch (systemctl is-enabled snapper-timeline.timer)
    case disabled
        ok 'snapper-timeline.timer disabled'
    case '*'
        fail "snapper-timeline.timer is $(systemctl is-enabled snapper-timeline.timer)"
end

switch (systemctl is-enabled snapper-cleanup.timer)
    case enabled
        ok 'snapper-cleanup.timer enabled'
    case '*'
        fail "snapper-cleanup.timer is $(systemctl is-enabled snapper-cleanup.timer)"
end

if grep -q '^MAX_SNAPSHOT_ENTRIES=2' /etc/default/limine
    ok 'Limine MAX_SNAPSHOT_ENTRIES=2'
else
    fail 'Limine MAX_SNAPSHOT_ENTRIES is not 2'
end

set limine_snaps (grep -oE 'snapshots/[0-9]+' /boot/limine.conf | sort -u)
set nlimine (count $limine_snaps)
if test $nlimine -le 2
    ok "Limine snapshot entries: $nlimine ($limine_snaps)"
else
    fail "Limine has $nlimine snapshot entries (want ≤2): $limine_snaps"
end

echo
df -h /
echo
echo 'sudo snapper list / get-config not checked (needs root)'

if test $failed -eq 1
    echo
    echo 'CHG-014 verify FAILED'
    exit 1
end
echo
echo 'CHG-014 verify OK'
exit 0
