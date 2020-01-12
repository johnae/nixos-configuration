#!/usr/bin/env sh

set -euo pipefail

NIX_PATH=nixpkgs="$(cat nixos-channel)"/nixexprs.tar.xz
NIX_PATH="$NIX_PATH":nixos-hardware="$(cat nixos-hardware-channel)"
export NIX_PATH

configuration=${1:-}

if [ -z "$configuration" ] || [ ! -e "$configuration" ]; then
    echo Please provide the system configuration path as the first and only argument
    exit 1
fi

NIXOS_SYSTEM_CONFIG="$configuration"
export NIXOS_SYSTEM_CONFIG

echo Building system derivation from "$configuration"
nix-build '<nixpkgs/nixos>' \
          -A config.system.build.isoImage -I nixos-config=iso.nix -o result-iso \
          --option extra-builtins-file "$(pwd)"/extra-builtins.nix