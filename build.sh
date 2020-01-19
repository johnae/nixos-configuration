#!/usr/bin/env sh

set -euo pipefail

NIX_PATH=nixpkgs="$(cat nixos-channel)"/nixexprs.tar.xz
export NIX_PATH

echo Building system derivations from default.nix 1>&2
nix-build --no-out-link \
          --option extra-builtins-file "$(pwd)"/extra-builtins.nix
