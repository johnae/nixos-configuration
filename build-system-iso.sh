#!/usr/bin/env sh

set -euo pipefail

NIX_PATH=nixpkgs="$(cat nixos-channel)"/nixexprs.tar.xz
export NIX_PATH

configuration=${1:-}

if [ -z "$configuration" ] || [ ! -e "$configuration" ]; then
    echo Please provide the system configuration path as the first and only argument
    exit 1
fi

export NIXOS_SYSTEM_CONFIG="$configuration"

echo Building system derivation from "$configuration"
nix-build '<nixpkgs/nixos>' \
          -A config.system.build.isoImage -I nixos-config=iso.nix -o result-iso \
          --option extra-builtins-file "$(pwd)"/extra-builtins.nix