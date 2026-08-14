#!/bin/bash
# Arch wrapper for Island Enterprise Browser (CHG-012).
# Mirrors the google-chrome AUR launcher so Wayland flags live in:
#   ~/.config/island-browser-flags.conf

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}

if [[ -f $XDG_CONFIG_HOME/island-browser-flags.conf ]]; then
	ISLAND_USER_FLAGS="$(grep -v '^#' "$XDG_CONFIG_HOME/island-browser-flags.conf")"
fi

export CHROME_WRAPPER="/opt/island/island-browser/island-browser"
export CHROME_VERSION_EXTRA="stable"
export GNOME_DISABLE_CRASH_DIALOG=SET_BY_GOOGLE_CHROME

# Word-split flags is intentional (same as google-chrome AUR).
exec /opt/island/island-browser/Island $ISLAND_USER_FLAGS "$@"
