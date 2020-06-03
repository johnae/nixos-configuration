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
    wireguard
  ];

  services.myk3s.enable = true;
  services.myk3s.docker = true;

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 10250;
      to = 10252;
    }
  ];
  networking.firewall.allowedTCPPorts = [ 22 6443 ];

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

}
