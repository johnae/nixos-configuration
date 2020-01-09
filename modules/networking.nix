{ config, lib, pkgs, ... }:

with lib;

{
  imports = mapAttrsToList (
    name: _: ./networking + "/${name}"
  )
  (filterAttrs
    (name: _: lib.hasSuffix ".nix" name)
    (readDir ./networking)
  );
}