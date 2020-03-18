{ pkgs }:
let
  imageMeta = builtins.fromJSON (builtins.readFile ./nixpkgs-image.json);
in
pkgs.dockerTools.pullImage imageMeta
