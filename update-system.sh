#!/usr/bin/env sh

set -euo pipefail

profile=/nix/var/nix/profiles/system
pathToConfig="$(./build.sh -A machines."$(hostname)")"

echo Ensuring nix-channel set in git repo is used
sudo nix-channel --add "$(cat nixos-channel | tr -d '\n')" nixos
sudo nix-channel --update

echo Updating system profile
sudo nix-env -p "$profile" --set "$pathToConfig"

echo Switching to new configuration
if ! sudo "$pathToConfig"/bin/switch-to-configuration switch; then
        echo "warning: error(s) occurred while switching to the new configuration" >&2
        exit 1
fi
