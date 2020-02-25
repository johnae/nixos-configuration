#!/usr/bin/env sh

set -euo pipefail

unset NIX_PATH NIXPKGS_CONFIG
NIX_PATH=nixpkgs="$(pwd)/nixpkgs.nix"
export NIX_PATH

NIX_OUTLINK=${NIX_OUTLINK:-}
args=

if [ -n "$NIX_OUTLINK" ]; then
    args="$args -o $NIX_OUTLINK"
else
    args="$args --no-out-link"
fi

echo Building "$@" 1>&2
nix-build $args --arg overlays [] --option extra-builtins-file "$(pwd)"/extra-builtins.nix $@
