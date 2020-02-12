{ pkgs, config, lib, options }:

let
  chrpkgsBall = builtins.fetchTarball {
    url =
      "https://github.com/colemickens/nixpkgs-chromium/archive/master.tar.gz";
  };
  chrpkgs = import chrpkgsBall;

in
{
  nixpkgs.config = import ../nixpkgs-config.nix;
  nixpkgs.overlays = import ../nixpkgs-overlays.nix;

  imports = [
    ../modules/sway.nix
    ../modules/i3-status.nix
    ../modules/theme.nix
    ../modules/mako.nix
    ./accounts.nix
    ./sway.nix
    ./mako.nix
    ./alacritty.nix
    ./ssh.nix
    ./gpg-agent.nix
    ./terminfo.nix
    ./i3-status.nix
    ./pulseaudio.nix
    ./firefox.nix
    ./redshift.nix
    ./mbsync.nix
    ./fish.nix
  ];

  home.packages = with pkgs; [
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
    mu
    edit
    edi
    bat
    mail
    wofi
    emacs-server
    alacritty
    project-select
    launch
    git-credential-pass
    sk-sk
    sk-run
    sk-window
    sk-passmenu
    #slacks
    browse-chromium
    add-wifi-network
    update-wifi-networks
    update-wireguard-keys
    spotify-cmd
    spotify-play-album
    spotify-play-track
    spotify-play-artist
    spotify-play-playlist
    wl-clipboard
    wl-clipboard-x11
    wf-recorder
    nordic
    nordic-polar

    # nixfmt ## using below instead
    nixpkgs-fmt
    google-cloud-sdk
    kubectl
    kustomize
    fzf # # for certain utilities that depend on it
    rust-analyzer-bin
    rnix-lsp

    gnome3.nautilus
    chrpkgs.chromium-dev-wayland
  ];

  xsession.pointerCursor = {
    package = pkgs.gnome3.defaultIconTheme;
    name = "Adwaita";
  };

  xdg.enable = true;

  xdg.configFile."nixpkgs/config.nix".source = ../nixpkgs-config.nix;
  xdg.configFile."nixpkgs/overlays".source = ../overlays;
  xdg.configFile."nixpkgs/pkgs".source = ../pkgs;

  home.file.".emacs".source =
    (pkgs.callPackage ../pkgs/my-emacs/config.nix {}).emacsConfig;

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
    extraConfig = {
      core.editor = "${pkgs.edi}/bin/edi -t";
      push.default = "upstream";
      pull.rebase = true;
      rebase.autoStash = true;
      url."git@github.com:".insteadOf = "https://github.com/";
      color = {
        ui = "auto";
        branch = "auto";
        status = "auto";
        diff = "auto";
        interactive = "auto";
        grep = "auto";
        decorate = "auto";
        showbranch = "auto";
        pager = true;
      };
      credential = {
        "https://github.com" = {
          username = "johnae";
          helper = "pass web/github.com/johnae";
        };
        "https://repo.insane.se" = {
          username = "johnae";
          helper = "pass web/repo.insane.se/johnae";
        };
      };
    };
  };

  programs.command-not-found.enable = true;
  programs.starship.enable = true;
  programs.starship.settings = {
    kubernetes.disabled = false;
    kubernetes.style = "bold blue";
    nix_shell.disabled = false;
    nix_shell.use_name = true;
    rust.symbol = " ";
  };

  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
  programs.direnv.enable = true;
  programs.password-store.enable = true;
  programs.skim.enable = true;

  services.lorri.enable = true;
  services.syncthing.enable = true;

}
