{ sources ? import ../sources.nix }:
[
  (import ../pkgs.nix)
  (import sources.nixpkgs-mozilla)
  (import sources.emacs-overlay)
  (_: _: { inherit sources; })
]
