#!/usr/bin/env sh

set -euo pipefail

NIX_PATH=nixpkgs="$(cat nixos-channel)"/nixexprs.tar.xz
NIX_PATH="$NIX_PATH":nixos-hardware="$(cat nixos-hardware-channel)"
export NIX_PATH

configuration=${1:-}

if [ -z "$configuration" ] || [ ! -e "$configuration" ]; then
    echo Please provide the system configuration path as the first and only argument 1>&2
    exit 1
fi

echo Building system derivation from "$configuration" 1>&2
nix-build '<nixpkgs/nixos>' --no-out-link -A system \
          -I nixos-config="$configuration" \
          --option extra-builtins-file "$(pwd)"/extra-builtins.nix