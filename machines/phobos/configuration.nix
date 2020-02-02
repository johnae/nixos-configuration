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
  users.groups = {
    "${userName}".gid = 1337;
    scard.gid = 1050;
  };
  users.extraUsers."${userName}" = {
    shell = pkgs.fish;
    extraGroups = [ "scard" ];
  };

  programs.sway.enable = true;
  nixpkgs.overlays = [
    (import ../../overlays/mozilla.nix)
  ];

  ## WIP
  home-manager.useUserPackages = true;
  home-manager.users."${userName}" = { ... }: {
    nixpkgs.overlays = [
      (import ../../overlays/pkgs.nix)
    ];
    imports = [
      ../../modules/sway.nix
      ../../modules/i3-status.nix
      ../../modules/theme.nix
      ../../home/sway.nix
      ../../home/alacritty.nix
      ../../home/ssh.nix
      ../../home/gpg-agent.nix
      ../../home/terminfo.nix
      ../../home/i3-status.nix
      ../../home/pulseaudio.nix
    ];
    home.packages = with pkgs;
      [
        sway
        swaybg
        swayidle
        swaylock
        xwayland
        iw
        mako
        spotifyd
        spotnix
        #i3status-rust
        my-emacs
        edit edi #ed emacs-run
        #mail
        #alacritty
        wofi
        emacs-server
        #edit
        #edi ed
        project-select
        terminal
        launch
        #git-credential-pass
        sk-sk sk-run sk-window sk-passmenu
        browse
        #slacks
        browse-chromium
        #start-sway
        random-background
        random-picsum-background
        add-wifi-network update-wifi-networks
        update-wireguard-keys
        spotify-cmd
        spotify-play-album
        spotify-play-track
        spotify-play-artist
        spotify-play-playlist
        wl-clipboard
        wl-clipboard-x11
        wf-recorder
        gtk2
        nordic
        nordic-polar
      ];

    xdg.enable = true;

    home.file.".icons/default" = {
      source = "${pkgs.gnome3.defaultIconTheme}/share/icons/Adwaita";
    };

    base16-theme.enable = true;

    qt = {
      enable = true;
      platformTheme = "gnome";
    };

    gtk = {
      enable = true;
      font = {
        package = pkgs.roboto;
        name = "Roboto Medium 11";
      };
      iconTheme = {
        package = pkgs.arc-icon-theme;
        name = "Arc";
      };
      theme = {
        package = pkgs.arc-theme;
        name = "Arc-Dark";
      };
    };

    programs.sway.settings.output = {
      "eDP-1" = {
        scale = "1.6";
        pos = "0 0";
      };
    };

    programs.git = {
      enable = true;
      userName = "John Axel Eriksson";
      userEmail = "john@insane.se";
    };

    programs.command-not-found.enable = true;
    programs.starship.enable = true;
    programs.starship.settings = {
      git_branch.symbol=" ";
      kubernetes.disabled = false;
      kubernetes.style = "bold blue";
      nix_shell.disabled = false;
      nix_shell.use_name = true;
      package.symbol = " ";
      rust.symbol = " ";
    };

    programs.lsd = {
      enable = true;
      enableAliases = true;
    };

    programs.direnv.enable = true;

    programs.password-store.enable = true;
    programs.skim.enable = true;

    programs.fish = {
      enable = true;
      shellAbbrs = {
        cat = "bat";
        g = "git";
      };
      shellAliases = {
        k8s-run = "${pkgs.kubectl}/bin/kubectl run tmp-shell --generator=run-pod/v1 --rm -i --tty --image=nixpkgs/nix-unstable --restart=Never --attach -- nix-shell -p bashInteractive --run bash";
      };
      shellInit = ''
        fish_vi_key_bindings ^ /dev/null
      '';
      loginShellInit = ''
        if test "$DISPLAY" = ""; and test (tty) = /dev/tty1; and test "$XDG_SESSION_TYPE" = "tty"
          export GDK_BACKEND=wayland
          export MOZ_ENABLE_WAYLAND=1
          export XCURSOR_THEME=default
          exec sway
        end
      '';
    };

    services.lorri.enable = true;
  };

}
