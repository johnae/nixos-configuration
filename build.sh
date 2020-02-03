#!/usr/bin/env sh

set -euo pipefail

NIX_OUTLINK=${NIX_OUTLINK:-}
args=

if [ -n "$NIX_OUTLINK" ]; then
    args="$args -o $NIX_OUTLINK"
else
    args="$args --no-out-link"
fi

echo Building "$@" 1>&2
nix-build $args --option extra-builtins-file "$(pwd)"/extra-builtins.nix $@
