{ config, pkgs, lib, ... }:

let
  nixosFunc = import (pkgs.path + "/nixos");
  configuration = builtins.getEnv "NIXOS_SYSTEM_CONFIG";
  metadataDir = toString ./metadata;
  confName = lib.removeSuffix ".nix" (builtins.baseNameOf configuration);
  isoConf = with builtins;
    let conf = "${metadataDir}/${confName}/isoconf.json";
    in if pathExists conf then extraBuiltins.sops conf else {};
  additionalVolumes = builtins.getEnv "ADDITIONAL_VOLUMES";
  additionalDisk = builtins.getEnv "ADDITIONAL_DISK";
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

    if ! ping -c 1 www.google.com; then
        cat<<EOF
    No network - please set it up, then exit the shell to continue.
    For example, on a laptop, you might want to run something like:

    wpa_supplicant -B -i INTERFACE -c <(wpa_passphrase 'NETWORK' 'PASSWORD')

    EOF
        bash
    fi

    ${lib.concatMapStringsSep "\n"
      (s: "export ${s}")
      (lib.mapAttrsToList (name: value: "${name}=\"${value}\"") isoConf)}

    sudo --preserve-env=DISK_PASSWORD,ADDITIONAL_VOLUMES,ADDITIONAL_DISK \
          /etc/install.sh

    sudo shutdown -h now
  '';

}