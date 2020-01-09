{ ... }:

let
  pkgs = import ./nixpkgs.nix;
  nixosFunc = import (pkgs.path + "/nixos");

  buildConfig = config:
    (nixosFunc { configuration = config; }).system;
in
{
  machines = pkgs.recurseIntoAttrs {
    europa = buildConfig ./machines/europa.nix;
    phobos = buildConfig ./machines/phobos.nix;
    rhea = buildConfig ./machines/rhea.nix;
    titan = buildConfig ./machines/titan.nix;
    hyperion = buildConfig ./machines/hyperion.nix;
  };
}