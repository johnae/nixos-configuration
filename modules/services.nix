{ config, lib, pkgs, ... }:

with lib;

{
  imports = mapAttrsToList (
    name: _: ./services + "/${name}"
  )
    (
      filterAttrs
        (name: _: hasSuffix ".nix" name)
        (builtins.readDir ./services)
    );
}
