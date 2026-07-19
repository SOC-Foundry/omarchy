#!/usr/bin/env fish
# CHG-007 verify — audio precedence + Rock EQ on 83te
# Usage: fish ~/Development/Projects/socfoundry/omarchy/scripts/chg007-verify.fish

set -l fail 0

function ok
    echo "  OK  $argv"
end
function bad
    echo "  FAIL $argv"
    set -g fail 1
end
function info
    echo "  --  $argv"
end

echo "=== CHG-007 verify "(date -Is)" ==="
echo

echo "--- services ---"
for u in wireplumber.service filter-chain.service audio-precedence-watch.service pipewire.service
    set -l st (systemctl --user is-active $u 2>/dev/null)
    if test "$st" = active
        ok "$u active"
    else
        bad "$u is $st"
    end
end
echo

echo "--- config files ---"
set -l home $HOME
for f in \
    $home/.config/wireplumber/wireplumber.conf.d/50-device-precedence.conf \
    $home/.config/wireplumber/wireplumber.conf.d/52-stream-music-eq.conf \
    $home/.config/wireplumber/wireplumber.conf.d/51-bluetooth-quality.conf \
    $home/.config/audio-eq/rock.conf \
    $home/.config/pipewire/filter-chain.conf.d/10-audio-eq.conf \
    $home/.local/bin/audio-precedence-follow \
    $home/.local/bin/audio-precedence-watch \
    $home/.config/systemd/user/audio-precedence-watch.service
    if test -e $f
        ok "present $f"
    else
        bad "missing $f"
    end
end
echo

echo "--- EQ state ---"
set -l eq_state (tr -d '[:space:]' <$home/.config/audio-eq/state 2>/dev/null)
if test "$eq_state" = rock
    ok "audio-eq state=rock"
else
    bad "audio-eq state=$eq_state (want rock)"
end

set -l sinks (pactl list short sinks 2>/dev/null | awk '{print $2}')
if contains effect_input.eq $sinks
    ok "EQ sink effect_input.eq present"
else
    bad "EQ sink effect_input.eq missing (filter-chain?)"
end

set -l def_sink (pactl get-default-sink 2>/dev/null)
if test "$def_sink" = effect_input.eq
    ok "default sink is effect_input.eq"
else
    # acceptable if EQ down and hardware selected
    info "default sink is $def_sink (expected effect_input.eq when EQ up)"
    if not contains effect_input.eq $sinks
        bad "neither EQ default nor EQ sink available"
    else
        bad "EQ present but default is $def_sink"
    end
end
echo

echo "--- sink priorities (wpctl inspect by node.name) ---"
set -l p30i_pri ""
set -l lenovo_pri ""
set -l builtin_pri ""

# Resolve wpctl object ids from inspect of each Audio/Sink id in status
for id in (wpctl status 2>/dev/null | string match -r '^\s+\*?\s+\d+\.' | string replace -r '^\s+\*?\s+(\d+)\..*' '$1')
    set -l insp (wpctl inspect $id 2>/dev/null)
    set -l nname (echo $insp | string match -r 'node.name = "[^"]+"' | string replace -r 'node.name = "([^"]+)"' '$1')
    set -l pri (echo $insp | string match -r 'priority.session = "[^"]+"' | string replace -r 'priority.session = "([^"]+)"' '$1')
    test -n "$nname"; or continue
    test -n "$pri"; or continue
    if string match -q 'bluez_output.F4_B6_2D_75_CE_92.*' $nname
        set p30i_pri $pri
        info "P30i $nname priority.session=$pri"
    else if string match -q '*Synaptics_Lenovo_USB-C*analog-stereo' $nname
        set lenovo_pri $pri
        info "Lenovo $nname priority.session=$pri"
    else if string match -q '*sof_sdw.pro-output-0' $nname
        set builtin_pri $pri
        info "Built-in $nname priority.session=$pri"
    end
end

if test -n "$p30i_pri" -a -n "$lenovo_pri"
    if test $p30i_pri -gt $lenovo_pri
        ok "P30i priority ($p30i_pri) > Lenovo ($lenovo_pri)"
    else
        bad "P30i priority ($p30i_pri) should be > Lenovo ($lenovo_pri)"
    end
else
    info "skip P30i/Lenovo priority compare (device missing)"
end
if test -n "$lenovo_pri" -a -n "$builtin_pri"
    if test $lenovo_pri -gt $builtin_pri
        ok "Lenovo priority ($lenovo_pri) > Built-in ($builtin_pri)"
    else
        bad "Lenovo priority ($lenovo_pri) should be > Built-in ($builtin_pri)"
    end
else
    info "skip Lenovo/Built-in priority compare (device missing)"
end
echo

echo "--- default source (mic precedence) ---"
set -l def_src (pactl get-default-source 2>/dev/null)
info "default source: $def_src"
if string match -q '*Camera*' $def_src; or string match -q '*Sonix*' $def_src
    bad "default source is camera mic — should prefer Lenovo / P30i / built-in"
else
    ok "default source is not camera"
end

# Prefer Lenovo or BT or built-in
if string match -q '*Lenovo*' $def_src; or string match -q '*bluez*' $def_src; or string match -q '*sof_sdw*' $def_src
    ok "default source is a precedence-class device"
else
    info "default source may be unexpected: $def_src"
end
echo

echo "--- built-in card profile ---"
set -l card_prof (pactl list cards 2>/dev/null | awk '
  /Name: alsa_card.pci-0000_00_1f.3-platform-sof_sdw/ {found=1}
  found && /Active Profile:/ {print $3; exit}
')
if test "$card_prof" = off
    bad "built-in sof_sdw profile is still off (need pro-audio or stereo-fallback)"
else
    ok "built-in sof_sdw Active Profile: $card_prof"
end
echo

echo "--- follow helper ---"
if test -x $home/.local/bin/audio-precedence-follow
    $home/.local/bin/audio-precedence-follow --print
    ok "audio-precedence-follow ran"
else
    bad "follow helper missing"
end
echo

echo "--- network DSCP (expected: none on host) ---"
if test -f /etc/nftables.d/qos-dscp.nft
    info "host has /etc/nftables.d/qos-dscp.nft (optional; LAN EF is primary)"
else
    ok "no host DSCP file (LAN handles EF) — as designed"
end
echo

if test $fail -eq 0
    echo "=== RESULT: PASS ==="
else
    echo "=== RESULT: FAIL (see above) ==="
end
exit $fail
