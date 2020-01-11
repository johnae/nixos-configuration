let
  pkgs = import ./nixpkgs.nix;
  metadata = builtins.fromJSON (builtins.readFile (toString ./nixos-hardware.json));
  nixos-hardware = with metadata; builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
  ## gotta be honest - I don't fully understand why I need to do this hackery and as far as I remember
  ## it hasn't always been necessary but what do I know. Basically stolen from: https://github.com/NixOS/nixpkgs/commit/4e78aeb441075872c07e6d6dc45f2045a3d87e41
  with builtins;
  seq
      (import (pkgs.writeText "discard.nix" "${substring 0 0 nixos-hardware}null\n"))
      (unsafeDiscardStringContext nixos-hardware)