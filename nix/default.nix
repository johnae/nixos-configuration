{ system ? null, config ? { }, sources ? import ./sources.nix, ... }:
import sources.nixpkgs (
  {
    overlays = [
      (import ./pkgs.nix)
      (import sources.nixpkgs-mozilla)
      (import sources.emacs-overlay)
      (_: _: { inherit sources; })
    ];
    inherit config;
  } //
  (if system != null then { inherit system; } else { })
)
