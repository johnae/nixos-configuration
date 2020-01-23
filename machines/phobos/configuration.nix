{ config, lib, pkgs, ... }:

let

  lib = pkgs.callPackage ./../../lib.nix { };

  hostName = "phobos";

  nixos-hardware = import ../../nixos-hardware.nix;

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = with builtins;
    fromJSON (extraBuiltins.sops ../../metadata/phobos/meta.json);

  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head ( attrNames ( filterAttrs (_: value: value.uid == 1337)
      secretConfig.users.extraUsers ));
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
    sshKey = "home/${userName}/.ssh/backup_id_rsa";
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

  ## WIP
  #home-manager.useUserPackages = true;
  #home-manager.users."${userName}" = { ... }: {
  #  home.packages = with pkgs;
  #    [
  #      sway
  #      swaybg
  #      swayidle
  #      swaylock
  #      mako
  #      i3status-rust
  #      my-emacs
  #    ];

  #  xdg.enable = true;
  #  xdg.configFile."sway/config".source = pkgs.callPackage ../../sway-config.nix { };
  #  programs.command-not-found.enable = true;
  #  programs.fish = {
  #    enable = true;
  #    shellInit = ''
  #      if test "$DISPLAY" = ""; and test (tty) = /dev/tty1; and test "$XDG_SESSION_TYPE" = "tty"
  #        exec sway
  #      end
  #    '';
  #  };
  #};

}
