{ config, lib, pkgs, ... }:

let

  hostName = "europa";

  nixos-hardware = import ../../nixos-hardware.nix;

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = with builtins;
    fromJSON (extraBuiltins.sops ../../metadata/europa/meta.json);

  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head ( attrNames ( filterAttrs (_: value: value.uid == 1337)
      secretConfig.users.extraUsers ));
in

{
  imports = [
    ../../defaults/laptop.nix
    "${nixos-hardware}/dell/xps/13-9370"
    ./hardware-configuration.nix
    secretConfig
  ];

  nix.trustedUsers = [ "root" userName ];

  networking = {
    inherit hostName;
    extraHosts = "127.0.1.1 ${hostName}";
  };

  environment.systemPackages = import ./system-packages.nix pkgs;

  ## trying to fix bluetooth disappearing after suspend
  powerManagement.powerDownCommands = ''
    systemctl stop bluetooth && rmmod btusb
  '';

  powerManagement.powerUpCommands = ''
    modprobe btusb && systemctl start bluetooth
  '';
  ## end fix

  services.rbsnapper = {
    enable = true;
    sshKey = "/home/${userName}/.ssh/backup_id_rsa";
  };

  services.syncthing = {
    enable = true;
    user = userName;
    group = userName;
    dataDir = "/home/${userName}/.config/syncthing";
    openDefaultPorts = true;
  };

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${userName}".gid = 1337;
  users.extraUsers."${userName}" = {
    shell = pkgs.fish;
  };

}
