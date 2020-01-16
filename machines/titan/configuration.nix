{ config, pkgs, lib, ... }:

let
  meta = builtins.extraBuiltins.sops ../metadata/titan/meta.json;
in

{
  imports = [
    ../../defaults/server.nix
    ./hardware-configuration.nix
  ];

  nix.trustedUsers = [ "root" "${meta.user.name}" ];

  networking = rec {
    inherit (meta) hostName hostId;
    extraHosts = "127.0.0.1 ${hostName}";
  };

  networking.interfaces.eth1.ipv4.addresses = [
    { address = meta.ipv4; prefixLength = 24; }
  ];
  networking.defaultGateway = meta.defaultGateway;

  services.k3s = meta.k3s;

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.extraUsers.root = {
    inherit (meta.user) hashedPassword;
  };
  users.groups."${meta.user.name}".gid = 1337;
  users.extraUsers."${meta.user.name}" = {
    isNormalUser = true;
    uid = 1337;
    extraGroups = [ "wheel" "docker" "video" "audio" ];
    shell = pkgs.fish;
    home = "/home/${meta.user.name}";
    inherit (meta.user) openssh description hashedPassword;
  };

}