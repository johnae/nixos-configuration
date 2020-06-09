{ config, lib, pkgs, ... }:
let
  loadSecretMetadata = path: with builtins;
    if getEnv "NIX_TEST" != ""
    then extraBuiltins.loadYAML (path + "/meta.test.yaml")
    else extraBuiltins.sops (path + "/meta.yaml");

  hostName = "europa";

  nixos-hardware = import ../../nix/nixos-hardware.nix;

  ## some of the important values come from secrets as they are
  ## sensitive - otherwise works like any module.
  secretConfig = loadSecretMetadata ../../metadata/europa;

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

  xps9370 = {
    imports = [
      "${nixos-hardware}/common/cpu/intel/kaby-lake"
      "${nixos-hardware}/common/pc/laptop"
    ];

    boot.kernelParams = [ "mem_sleep_default=deep" ];
    boot.blacklistedKernelModules = [ "psmouse" ];
    services.throttled.enable = lib.mkDefault true;
    services.thermald.enable = true;
  };

  fwsvccfg = config.systemd.services.firewall;
  fwcfg = config.networking.firewall;
in
with lib; {
  imports = [
    ../../defaults/laptop.nix
    xps9370
    #"${nixos-hardware}/dell/xps/13-9370"
    ./hardware-configuration.nix
    secretConfig
  ];

  nix.trustedUsers = [ "root" userName ];

  networking = {
    inherit hostName;
    extraHosts = "127.0.1.1 ${hostName}";
    wireguard.interfaces.vpn.postSetup = ''
      printf "nameserver 193.138.218.74" | ${pkgs.openresolv}/bin/resolvconf -a vpn -m 0
    '';
  };

  systemd.services.firewall-private = {
    inherit (fwsvccfg) wantedBy reloadIfChanged;
    wants = [ "wireguard-vpn.service" ];
    unitConfig = {
      inherit (fwsvccfg.unitConfig) ConditionCapability DefaultDependencies;
    };
    path = [ fwcfg.package ];
    description = fwsvccfg.description + " in netns private";
    after = fwsvccfg.after ++ [ "wireguard-vpn.service" ];
    serviceConfig = with fwsvccfg.serviceConfig; {
      inherit Type RemainAfterExit;
      ExecStart = "${pkgs.iproute}/bin/ip netns exec private " + (lib.last (lib.splitString "@" ExecStart));
      ExecReload = "${pkgs.iproute}/bin/ip netns exec private " + (lib.last (lib.splitString "@" ExecReload));
      ExecStop = "${pkgs.iproute}/bin/ip netns exec private " + (lib.last (lib.splitString "@" ExecStop));
    };
  };

  boot.btrfsCleanBoot = {
    enable = true;
    wipe = [ "@" "@var" ];
    keep = [
      "/var/lib/bluetooth"
      "/var/lib/iwd"
      "/var/lib/wireguard"
      "/var/lib/systemd"
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
        scale = "2.0";
        pos = "0 0";
      };
    };

  };

}
