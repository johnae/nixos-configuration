#!/usr/bin/env sh

set -euo pipefail

echo Building "$@" 1>&2
nix-build --no-out-link --option extra-builtins-file "$(pwd)"/extra-builtins.nix $@
