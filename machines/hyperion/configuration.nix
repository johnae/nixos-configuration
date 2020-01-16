{ config, pkgs, lib, ... }:

let
  hostName = "hyperion";

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = with builtins;
    fromJSON (extraBuiltins.sops ../../metadata/hyperion/meta.json);

  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head ( attrNames ( filterAttrs (_: value: value.uid == 1337)
      secretConfig.users.extraUsers ));
in

{
  imports = [
    ../../defaults/server.nix
    ./hardware-configuration.nix
    secretConfig
  ];

  nix.trustedUsers = [ "root" userName ];

  networking = {
    inherit hostName;
    extraHosts = "127.0.1.1 ${hostName}";
  };

  services.k3s = {
    enable = true;
    nodeName = hostName;
  }

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${userName}".gid = 1337;
  users.extraUsers."${userName}" = {
    shell = pkgs.fish;
  };

}