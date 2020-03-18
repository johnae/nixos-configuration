{ system ? null, config ? { }, ... }:

import ./nixpkgs.nix (
  {
    overlays = (import ./nixpkgs-overlays.nix);
  }
  // (if system != null then { inherit system; } else { })
  // { inherit config; }
)
