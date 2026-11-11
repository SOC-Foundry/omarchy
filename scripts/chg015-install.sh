#!/usr/bin/env bash
# CHG-015 — install Syncthing 1.30.0 and pin it.
#
# Omarchy 4.5's repo package is 2.x. The mesh is 1.30.0. Do not
# `pacman -S syncthing`. This does not start the service and does not
# edit any other machine.
set -u

if [[ $(id -u) -eq 0 ]]; then
  echo "run as kthompson, not root. The script calls sudo itself." >&2
  exit 1
fi

sudo -v || exit 1

URL=https://archive.archlinux.org/packages/s/syncthing/syncthing-1.30.0-1-x86_64.pkg.tar.zst
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
curl -fLO "$URL"
sudo pacman -U --noconfirm ./syncthing-1.30.0-1-x86_64.pkg.tar.zst

if ! awk '/^\[options\]/{in_opt=1; next} /^\[/{in_opt=0} in_opt && /^IgnorePkg[[:space:]]*=.*\bsyncthing\b/{found=1} END{exit !found}' /etc/pacman.conf; then
  TS=$(date +%Y%m%d-%H%M%S)
  sudo cp -a /etc/pacman.conf "/etc/pacman.conf.bak.chg015.${TS}"
  sudo awk '
    BEGIN { in_opt=0; added=0 }
    /^\[options\]/ { print; in_opt=1; next }
    /^\[/ && in_opt && !added {
      print "IgnorePkg = syncthing"
      print ""
      added=1; in_opt=0
      print; next
    }
    { print }
    END { if (in_opt && !added) print "IgnorePkg = syncthing" }
  ' /etc/pacman.conf | sudo tee /etc/pacman.conf.new >/dev/null
  sudo mv /etc/pacman.conf.new /etc/pacman.conf
fi

if systemctl is-active --quiet ufw; then
  for net in 172.31.255.128/26 172.31.255.192/26; do
    if ! sudo ufw status | grep -q "22000/tcp.*${net}"; then
      sudo ufw allow from "$net" to any port 22000 proto tcp
    fi
  done
fi

syncthing --version
systemctl --user is-enabled syncthing.service 2>/dev/null || true
systemctl --user is-active syncthing.service 2>/dev/null || true
echo "Installed and pinned. Service was not started."
