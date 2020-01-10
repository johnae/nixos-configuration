{ config, pkgs, lib, ... }:

let
  pkgs = import ./nixpkgs.nix;
  nixosFunc = import (pkgs.path + "/nixos");
  configuration = builtins.getEnv "NIXOS_SYSTEM_CONFIG";
  confDir = builtins.dirOf configuration;
  confName = lib.removeSuffix ".nix" (builtins.baseNameOf configuration);
  isoConf = with builtins;
    let conf = "${confDir}/${confName}/isoconf.json";
    in if pathExists conf then fromJSON (readFile conf) else {};
  additionalVolumes = builtins.getEnv "ADDITIONAL_VOLUMES";
  additionalDisk = builtins.getEnv "ADDITIONAL_DISK";
  diskPassword = builtins.extraBuiltins.sops;
  buildConfig = config:
    (nixosFunc { configuration = config; }).system;
  system-closure = buildConfig configuration;
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  environment.etc = {
    "install.sh" = {
      source = ./install.sh;
      mode = "0700";
    };
    "system-closure-path" = {
      text = toString system-closure;
    };
  };

  isoImage.storeContents = [ system-closure ];

  environment.etc."profile.local".text = ''
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

    ${lib.concatMapStringsSep "\n"
      (s: "export ${s}")
      (lib.mapAttrsToList (name: value: "${name}=\"${value}\"") isoConf)}

    sudo --preserve-env=DISK_PASSWORD,ADDITIONAL_VOLUMES,ADDITIONAL_DISK \
          /etc/install.sh

    sudo shutdown -h now
  '';

}