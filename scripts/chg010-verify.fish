#!/usr/bin/env fish
# CHG-010 verify — five-tier audio precedence (AUX between USB-C and built-in)
# Session 10 · Chapter X. Shared checks live in chg007-verify.fish.
# Usage: fish ~/Development/Projects/socfoundry/omarchy/scripts/chg010-verify.fish

set -l self (status filename)
set -l dir (dirname $self)
source $dir/chg007-verify.fish
