{ config, pkgs, lib, ... }:
let
  loadSecretMetadata = path: with builtins;
    if getEnv "NIX_TEST" != ""
    then fromJSON (readFile (path + "/meta.test.json"))
    else fromJSON (extraBuiltins.sops (path + "/meta.json"));
  hostName = "titan";

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = loadSecretMetadata ../../metadata/titan;

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

  virtualisation.docker.enable = true;
  services.k3s = {
    enable = true;
    nodeName = hostName;
    flannelBackend = "none";
    extraManifests = [ ../../modules/services/k3s/calico.yaml ];
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${userName}".gid = 1337;
  users.extraUsers."${userName}" = { shell = pkgs.fish; };

}
