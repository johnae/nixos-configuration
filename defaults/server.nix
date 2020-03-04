{ config, lib, pkgs, ... }:
let
  nixos-hardware = import ../nix/nixos-hardware.nix;
in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    ./defaults.nix
  ];

  networking.usePredictableInterfaceNames = false; ## works when there's only one ethernet port
  networking.useDHCP = false;

  console.font = "Lat2-Terminus16";

  environment.systemPackages = with pkgs; [
    wget
    vim
    curl
    man-pages
    cacert
    zip
    unzip
    jq
    git
    fd
    lsof
    fish
  ];

  services.openssh.enable = true;
  services.k3s.enable = true;
  networking.firewall.enable = false;

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

}
