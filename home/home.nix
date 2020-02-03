{ pkgs, config, lib, options }:

{
  nixpkgs.config = import ../nixpkgs-config.nix;
  nixpkgs.overlays = import ../nixpkgs-overlays.nix;

  imports = [
    ../modules/sway.nix
    ../modules/i3-status.nix
    ../modules/theme.nix
    ./sway.nix
    ./alacritty.nix
    ./ssh.nix
    ./gpg-agent.nix
    ./terminfo.nix
    ./i3-status.nix
    ./pulseaudio.nix
    ./firefox.nix
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
      #latest.firefox-nightly-bin
    ];

  xdg.enable = true;

  xdg.configFile."nixpkgs/config.nix".source = ../nixpkgs-config.nix;
  xdg.configFile."nixpkgs/overlays".source = ../overlays;
  xdg.configFile."nixpkgs/pkgs".source = ../pkgs;

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

  programs.git = {
    enable = true;
    userName = "John Axel Eriksson";
    userEmail = "john@insane.se";
    signing = {
      key = "0x04ED6F42C62F42E9";
      signByDefault = true;
    };
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
  services.syncthing.enable = true;

}
