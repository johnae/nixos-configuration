{ system ? null, config ? { }, sources ? import ./sources.nix, ... }:
import sources.nixpkgs (
  {
    overlays = (import ./overlays/overlays.nix { inherit sources; });
    inherit config;
  } //
  (if system != null then { inherit system; } else { })
)
