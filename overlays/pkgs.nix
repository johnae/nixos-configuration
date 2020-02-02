self: super:

let
  importFromGithubMeta = with builtins; path:
    import (super.fetchFromGitHub (fromJSON (readFile path)));
in
rec {
  k3s = super.callPackage ../pkgs/k3s { };
  system-san-francisco-font = super.callPackage ../pkgs/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../pkgs/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../pkgs/office-code-pro-font { };
  jet-brains-mono-font = super.callPackage ../pkgs/jet-brains-mono-font { };
  btr-snap = super.callPackage ../pkgs/btr-snap { };
  redshift-wl = super.callPackage ../pkgs/redshift {
    inherit (super.python3Packages) python pygobject3 pyxdg wrapPython;
    geoclue = super.geoclue2;
  };

  lorri = importFromGithubMeta ./lorri.json { };

  #sway = super.callPackage ../pkgs/sway { };
  #swaybg = super.callPackage ../pkgs/swaybg { };
  #swayidle = super.callPackage ../pkgs/swayidle { };
  #swaylock = super.callPackage ../pkgs/swaylock { };
  #wlroots = super.callPackage ../pkgs/wlroots { };
  alacritty = super.callPackage ../pkgs/alacritty { };
  fire = super.callPackage ../pkgs/fire { };
  grim = super.callPackage ../pkgs/grim { };
  #i3status-rust = super.callPackage ../pkgs/i3status-rust { };
  mako = super.callPackage ../pkgs/mako { };
  my-emacs = super.callPackage ../pkgs/my-emacs { };
  persway = super.callPackage ../pkgs/persway { };
  rust-analyzer = super.callPackage ../pkgs/rust-analyzer { };
  #scdoc = super.callPackage ../pkgs/scdoc { };
  slurp = super.callPackage ../pkgs/slurp { };
  spook = super.callPackage ../pkgs/spook { };
  spotifyd = super.callPackage ../pkgs/spotifyd { };
  spotnix = super.callPackage ../pkgs/spotnix { };
  wf-recorder = super.callPackage ../pkgs/wf-recorder { };
  wl-clipboard = super.callPackage ../pkgs/wl-clipboard { };
  wl-clipboard-x11 = super.callPackage ../pkgs/wl-clipboard-x11 { };
  wofi = super.callPackage ../pkgs/wofi { };
  xdg-desktop-portal-wlr = super.callPackage ../pkgs/xdg-desktop-portal-wlr { };

  inherit (super.callPackage ../pkgs/strictShellScript.nix { })
    writeStrictShellScript writeStrictShellScriptBin;

  initInstall = super.callPackage ../pkgs/initInstall.nix { };

  inherit ((super.callPackage ../pkgs/scripts { }).paths)
    edit edi #ed emacs-run
    emacs-server
    fzf-fzf project-select
    terminal launch
    fzf-passmenu rofi-passmenu
    fzf-run fzf-window
    sk-sk sk-run sk-window sk-passmenu
    browse-chromium
    rename-workspace screenshot
    random-background random-name
    random-picsum-background
    add-wifi-network update-wifi-networks
    update-user-nixpkg update-user-nixpkgs update-wireguard-keys
    spotify-play-album spotify-play-track spotify-cmd
    spotify-play-artist spotify-play-playlist
    swayidle-helper systemd-dbus-helper sway-background
    rotating-background toggle-keyboard-layouts;
}