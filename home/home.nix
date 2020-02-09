{ pkgs, config, lib, options }:

{
  nixpkgs.config = import ../nixpkgs-config.nix;
  nixpkgs.overlays = import ../nixpkgs-overlays.nix;

  imports = [
    ../modules/sway.nix
    ../modules/i3-status.nix
    ../modules/theme.nix
    ../modules/mako.nix
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
      edit edi
      bat
      mail
      wofi
      emacs-server
      alacritty
      project-select
      launch
      #git-credential-pass
      sk-sk sk-run sk-window sk-passmenu
      #slacks
      browse-chromium
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
      nordic
      nordic-polar

      google-cloud-sdk
      kubectl
      kustomize
      fzf ## for certain utilities that depend on it
      rust-analyzer

      gnome3.nautilus
    ];

  xsession.pointerCursor = {
    package = pkgs.gnome3.defaultIconTheme;
    name = "Adwaita";
  };

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
  programs.fish = {
    enable = true;
    shellAbbrs = {
      cat = "bat";
      g = "git";
    };
    shellAliases = {
      k8s-run = "${pkgs.kubectl}/bin/kubectl run tmp-shell --generator=run-pod/v1 --rm -i --tty --image=nixpkgs/nix-unstable --restart=Never --attach -- nix-shell -p bashInteractive --run bash";
    };
    shellInit = with pkgs; ''
      source ${skim}/share/skim/key-bindings.fish
      set fish_greeting
      fish_vi_key_bindings ^ /dev/null

      function fish_user_key_bindings
        skim_key_bindings

        function skim-jump-to-project-widget -d "Show list of projects"
          set -q SK_TMUX_HEIGHT; or set SK_TMUX_HEIGHT 40%
          begin
            set -lx SK_DEFAULT_OPTS "--height $SK_TMUX_HEIGHT $SK_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $SK_CTRL_R_OPTS +m"
            set -lx dir (${project-select}/bin/project-select ~/Development ~/.config)
            if [ "$dir" != "" ]
              cd $dir
              set -lx file (${fd}/bin/fd -H -E "\.git" . | "${skim}"/bin/sk)
              if [ "$file" != "" ]
                ${edi}/bin/edi "$file"
              end
            end
          end
          commandline -f repaint
        end
        bind \cg skim-jump-to-project-widget
        if bind -M insert > /dev/null 2>&1
          bind -M insert \cg skim-jump-to-project-widget
        end
        function skim-jump-to-file-widget -d "Show list of file to open in editor"
          set -q SK_TMUX_HEIGHT; or set SK_TMUX_HEIGHT 40%
          begin
            set -lx SK_DEFAULT_OPTS "--height $SK_TMUX_HEIGHT $SK_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $SK_CTRL_R_OPTS +m"
            set -lx file (${fd}/bin/fd -H -E "\.git" . | "${skim}"/bin/sk)
            if [ "$file" != "" ]
              ${edi}/bin/edi "$file"
            end
          end
          commandline -f repaint
        end
        bind \cf skim-jump-to-project-widget
        if bind -M insert > /dev/null 2>&1
          bind -M insert \cf skim-jump-to-file-widget
        end
        function kubectx-select -d "Select kubernetes cluster"
          ${kubectx}/bin/kubectx
        end
        bind \ck kubectx-select
        if bind -M insert > /dev/null 2>&1
          bind -M insert \ck kubectx-select
        end
        function kubens-select -d "Select kubernetes namespace"
          ${kubectx}/bin/kubens
        end
        bind \cn kubectx-select
        if bind -M insert > /dev/null 2>&1
          bind -M insert \cn kubens-select
        end
        function gcloud-project-select -d "Select gcloud project"
          set proj (${google-cloud-sdk}/bin/gcloud projects list | tail -n +2 | ${gawk}/bin/awk '{print $1}' | ${skim}/bin/sk)
          gcloud config set project $proj
        end
        bind \cw gcloud-project-select
        if bind -M insert > /dev/null 2>&1
          bind -M insert \cw gcloud-project-select
        end
      end
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
