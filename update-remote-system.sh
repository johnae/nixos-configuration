#!/usr/bin/env sh

set -euo pipefail

machine=${1:-}

profile=/nix/var/nix/profiles/system
pathToConfig="$(./build.sh -A machines."$machine")"

export NIX_SSHOPTS="-T -o RemoteCommand=none"

CHANNEL="$(cat nixos-channel | tr -d '\n')"

echo Copying closure to remote
nix-copy-closure "$machine" "$pathToConfig"

## below requires sudo without password on remote, also requires an ssh config
## where the given machines are configured so they can be accessed via their
## names
ssh "$machine" -t -o RemoteCommand=none nix-shell -p bash --run bash <<SSH

echo Ensuring nix-channel set in git repo is used
sudo nix-channel --add '$CHANNEL' nixos && sudo nix-channel --update

sudo nix-env -p '$profile' --set '$pathToConfig'
echo Updating system profile

echo Switching to new configuration
if ! sudo '$pathToConfig'/bin/switch-to-configuration switch; then
    echo "warning: error(s) occurred while switching to the new configuration" >&2
    exit 1
fi

SSH