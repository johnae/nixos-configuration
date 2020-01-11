{ config, lib, pkgs, ... }:

let
  nixos-hardware = (import ../nixos-hardware.nix).nixos-hardware;
in
{
  imports = [
    "${nixos-hardware}/common/pc/ssd"
    ../modules
    ./defaults.nix
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [ wireguard ];

  boot.kernel.sysctl = {
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.laptop_mode" = 5;
      "vm.swappiness" = 1;
      "fs.inotify.max_user_watches" = 12288;
  };

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.u2f.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.support32Bit = true;
  hardware.bluetooth.enable = true;
  networking.wireless.iwd.enable = true;

  console.font = "latarcyrheb-sun32";

  environment.pathsToLink = [ "/etc/gconf" ];

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  virtualisation.docker.enable = true;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.gnupg.dirmngr.enable = true;

  programs.ssh.startAgent = false;

  programs.dconf.enable = true;
  programs.light.enable = true;

  services.kbfs.enable = true;
  services.keybase.enable = true;

  services.pcscd.enable = true;
  services.cron.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.gvfs.enable = true;
  #services.gnome3.gnome-keyring.enable = true;
  services.gnome3.sushi.enable = true;
  services.openssh.enable = true;

  services.interception-tools.enable = true;

  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  services.dbus.packages = with pkgs; [ gnome2.GConf gnome3.gcr gnome3.dconf gnome3.sushi ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  services.logind.lidSwitch = "suspend-then-hibernate";
  environment.etc."systemd/sleep.conf".text = "HibernateDelaySec=8h";

  ## the NixOS module doesn't work well when logging in from console
  ## which is the case when running sway - a wayland compositor (eg. no x11 yay)
  ## actually - the redshift package (see below) is a patched version that works
  ## with wayland
  systemd.user.services.redshift =
  {
    description = "Redshift color temperature adjuster";
    wantedBy = [ "default.target" ];
    enable = true;
    serviceConfig = {
      ExecStart = ''
        ${pkgs.redshift-wl}/bin/redshift \
          -l 59.344:18.045 \
          -t 6500:2700 \
          -b 1:1 \
          -m wayland
      '';
      RestartSec = 3;
      Restart = "always";
    };
  };

  services.upower.enable = true;
  services.disable-usb-wakeup.enable = true;
  services.pasuspender.enable = true;

  fonts.fonts = with pkgs; [
     google-fonts
     source-code-pro
     office-code-pro-font
     system-san-francisco-font
     san-francisco-mono-font
     font-awesome_5
     powerline-fonts
     roboto
     fira-code
     fira-code-symbols
     nerdfonts
  ];

}