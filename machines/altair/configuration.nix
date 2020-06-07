{ config, pkgs, lib, ... }:
let
  hostName = "altair";

  loadSecretMetadata = path: with builtins;
    if getEnv "NIX_TEST" != ""
    then extraBuiltins.loadYAML (path + "/meta.test.yaml")
    else extraBuiltins.sops (path + "/meta.yaml");

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = loadSecretMetadata ../../metadata/altair;

  ## determine what username we're using so we define it in one
  ## place
  userName = with lib;
    head (
      attrNames (
        filterAttrs
          (_: value: hasAttr "uid" value && value.uid == 1337)
          secretConfig.users.extraUsers
      )
    );

  transmission = config.services.transmission;
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
    flannelBackend = "wireguard";
    cniPackage = pkgs.cni-plugins;
  };

  services.transmission = {
    enable = true;
    downloadDirPermissions = "775";
  };

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "transmission";
    group = "transmission";
  };

  systemd.services.transmission = {
    serviceConfig.ExecStart = lib.mkForce "/run/wrappers/bin/netns-exec private ${pkgs.transmission}/bin/transmission-daemon -f --port ${toString config.services.transmission.port} --config-dir ${config.services.transmission.home}/.config/transmission-daemon";
  };

  systemd.services.transmission-forwarder = {
    enable = true;
    after = [ "transmission.service" ];
    bindsTo = [ "transmission.service" ];
    script = ''
      ${pkgs.socat}/bin/socat tcp-listen:9091,fork,reuseaddr,bind=127.0.0.1  exec:'/run/wrappers/bin/netns-exec private ${pkgs.socat}/bin/socat STDIO "tcp-connect:127.0.0.1:9091"',nofork
    '';
  };

  boot = with secretConfig;
    let
      address = (builtins.head networking.interfaces.eth0.ipv4.addresses).address;
      subnet = "255.255.255.192"; ## fixme
      defaultGateway = networking.defaultGateway;
    in
    {

      loader.systemd-boot.enable = lib.mkForce false;
      loader.efi.canTouchEfiVariables = lib.mkForce false;

      loader.grub.enable = true;
      loader.grub.devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
      loader.grub.enableCryptodisk = true;
      kernelParams = [
        "ip=${address}::${defaultGateway}:${subnet}:${hostName}:eth0:none"
      ];


      initrd.extraUtilsCommandsTest = lib.mkForce "";
      initrd.availableKernelModules = [ "r8169" ];
      initrd.network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [
            "/etc/nixos/initrd_keys/dsa_key"
            "/etc/nixos/initrd_keys/rsa_key"
            "/etc/nixos/initrd_keys/ed25519_key"
          ];
          authorizedKeys = users.extraUsers."${userName}".openssh.authorizedKeys.keys;
        };
        postCommands = ''
          echo 'cryptsetup-askpass' >> /root/.profile
        '';
      };
    };

  hardware.cpu.intel.updateMicrocode = lib.mkForce false;
  hardware.cpu.amd.updateMicrocode = true;

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.groups."${userName}".gid = 1337;
  users.extraUsers."${userName}" = { shell = pkgs.fish; };

}
