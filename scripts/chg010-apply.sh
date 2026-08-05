#!/usr/bin/env bash
# CHG-010 apply — AUX desk headset in the audio precedence chain (83te)
#
# Session 10 · Chapter X. Installs the current audio stack (extends CHG-007):
#   P30i → Lenovo USB-C → AUX 3.5mm → built-in speakers/dmic → camera last
#
# Backups use *.bak.chg010.<timestamp>. Shared installer lives in chg007-apply.sh.
#
# Run as the desktop user (NOT root):
#   bash ~/Development/Projects/socfoundry/omarchy/scripts/chg010-apply.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export CHG_TAG=chg010
exec bash "$DIR/chg007-apply.sh" "$@"
