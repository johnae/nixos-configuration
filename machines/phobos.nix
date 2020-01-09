{ config, lib, pkgs, ... }:

let
  meta = builtins.extraBuiltins.sops ../metadata/phobos/meta.json;
  nixos-hardware = (import ../nixos-hardware.nix).nixos-hardware;
in

{
  imports = [
    ../defaults/laptop.nix
    #"${nixos-hardware}/dell/xps/13-9370"
    /etc/nixos/hardware-configuration.nix
    #wireguard
  ];

  nix.trustedUsers = [ "root" "${meta.user.name}" ];

  networking.hostName = meta.hostName;
  networking.extraHosts = "127.0.1.1 ${meta.hostName}";

  environment.systemPackages = import ./phobos/system-packages.nix pkgs;

  ## trying to fix bluetooth disappearing after suspend
  powerManagement.powerDownCommands = ''
    systemctl stop bluetooth && rmmod btusb
  '';

  powerManagement.powerUpCommands = ''
    modprobe btusb && systemctl start bluetooth
  '';
  ## end fix

  programs.ssh.knownHosts = meta.knownHosts;

  services.syncthing = {
    enable = true;
    user = meta.user.name;
    group = meta.user.name;
    dataDir = "/home/${meta.user.name}/.config/syncthing";
    openDefaultPorts = true;
  };

  services.rbsnapper = {
    enable = true;
    inherit (meta.backup) destination port sshKey;
  };

  security.pam.services."${meta.user.name}".enableGnomeKeyring = true;
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${meta.user.name}".gid = 1337;
  users.extraUsers."${meta.user.name}" = {
    isNormalUser = true;
    uid = 1337;
    extraGroups = [ "wheel" "docker" "video" "audio" ];
    shell = pkgs.fish;
    inherit (meta.user) description hashedPassword;
  };

}