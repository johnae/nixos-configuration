{ config, lib, pkgs, ... }:

{
  nix.extraOptions = ''
    plugin-files = ${pkgs.nix-plugins.override { nix = config.nix.package; }}/lib/nix/plugins/libnix-extra-builtins.so
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.cpu.intel.updateMicrocode = true;
  networking.nameservers = [ "1.0.0.1" "1.1.1.1" "2606:4700:4700::1111" ];

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Europe/Stockholm";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../overlays/pkgs.nix)
  ];

  environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];

  programs.fish.enable = true;

  system.stateVersion = "20.03";
}