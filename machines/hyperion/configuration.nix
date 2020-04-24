{ config, pkgs, lib, ... }:
let
  loadSecretMetadata = path: with builtins;
    if getEnv "NIX_TEST" != ""
    then extraBuiltins.loadYAML (path + "/meta.test.yaml")
    else extraBuiltins.sops (path + "/meta.yaml");
  hostName = "hyperion";

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = loadSecretMetadata ../../metadata/hyperion;


  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head (
      attrNames
        (
          filterAttrs (_: value: hasAttr "uid" value && value.uid == 1337)
            secretConfig.users.extraUsers
        )
    );
in
{
  imports =
    [ ../../defaults/server.nix ./hardware-configuration.nix secretConfig ];

  nix.trustedUsers = [ "root" userName ];

  networking = {
    inherit hostName;
    extraHosts = "127.0.1.1 ${hostName}";
  };

  services.myk3s = {
    nodeName = hostName;
    flannelBackend = "none";
    extraManifests = [ ../../files/k3s/calico.yaml ];
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${userName}".gid = 1337;
  users.extraUsers."${userName}" = { shell = pkgs.fish; };

}
