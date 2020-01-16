#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops

export SOPS_PGP_FP="06CAFD66CE7222C7FB0CA84314B5564DEB730BF5"

set -euo pipefail

f=$(mktemp)
trap "rm $f" EXIT
sops -d "$1" > $f
nix-instantiate --eval -E "builtins.readFile $f"