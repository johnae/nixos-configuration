with builtins;
let
  pkgs-meta = with builtins; fromJSON (readFile ./nixpkgs.json);
in
import (fetchTarball { inherit (pkgs-meta) url sha256; })
