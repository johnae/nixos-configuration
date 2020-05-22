{ config, lib, pkgs, ... }:
let
  loadSecretMetadata = path: with builtins;
    if getEnv "NIX_TEST" != ""
    then extraBuiltins.loadYAML (path + "/meta.test.yaml")
    else extraBuiltins.sops (path + "/meta.yaml");
  hostName = "phobos";

  nixos-hardware = import ../../nix/nixos-hardware.nix;

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = loadSecretMetadata ../../metadata/phobos;

  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head (
      attrNames (
        filterAttrs
          (_: value: value.uid == 1337)
          secretConfig.users.extraUsers
      )
    );
in
with lib; {
  imports = [
    ../../defaults/laptop.nix
    "${nixos-hardware}/dell/xps/13-9360"
    ./hardware-configuration.nix
    secretConfig
  ];

  nix.trustedUsers = [ "root" userName ];

  networking = {
    inherit hostName;
    extraHosts = "127.0.1.1 ${hostName}";
  };

  boot.btrfsCleanBoot = {
    enable = true;
    wipe = [ "@" "@var" ];
    keep = [
      "/var/lib/bluetooth"
      "/var/lib/iwd"
      "/var/lib/wireguard"
      "/root"
    ];
  };

  environment.systemPackages = import ./system-packages.nix pkgs;

  ## trying to fix bluetooth disappearing after suspend
  sleepManagement = {
    enable = true;
    sleepCommands = ''
      ${pkgs.libudev}/bin/systemctl stop bluetooth && ${pkgs.kmod}/bin/modprobe -r btusb
    '';
    wakeCommands = ''
      ${pkgs.kmod}/bin/modprobe btusb && ${pkgs.libudev}/bin/systemctl start bluetooth
    '';
  };
  ## end fix

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups = {
    "${userName}".gid = 1337;
    scard.gid = 1050;
  };
  users.extraUsers."${userName}" = {
    shell = pkgs.fish;
    extraGroups = [ "scard" ];
  };

  programs.sway.enable = true;
  home-manager.useUserPackages = true;
  home-manager.users."${userName}" = { ... }: {
    imports = [ ../../home/home.nix ];

    wayland.windowManager.sway.config.output = {
      "eDP-1" = {
        scale = "1.6";
        pos = "0 0";
      };
    };

  };

}
