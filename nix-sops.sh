#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops
set -euo pipefail

export SOPS_PGP_FP="782517BE26FBB0CC5DA3EFE59D91E5C4D9515D9E"
## can't read from fifo's it seems, which is a bit unfortunate
sops exec-file --no-fifo "$1" 'nix-instantiate --eval -E "builtins.readFile {}"'