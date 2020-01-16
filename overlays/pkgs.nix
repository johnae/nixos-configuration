self: super: rec {
  k3s = super.callPackage ../pkgs/k3s { };
  system-san-francisco-font = super.callPackage ../pkgs/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../pkgs/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../pkgs/office-code-pro-font { };
  btr-snap = super.callPackage ../pkgs/btr-snap { };
  redshift-wl = super.callPackage ../pkgs/redshift {
    inherit (super.python3Packages) python pygobject3 pyxdg wrapPython;
    geoclue = super.geoclue2;
  };

  sway = super.callPackage ../pkgs/sway { };
  swaybg = super.callPackage ../pkgs/swaybg { };
  swayidle = super.callPackage ../pkgs/swayidle { };
  swaylock = super.callPackage ../pkgs/swaylock { };
  wlroots = super.callPackage ../pkgs/wlroots { };
  alacritty = super.callPackage ../pkgs/alacritty { };
  fire = super.callPackage ../pkgs/fire { };
  grim = super.callPackage ../pkgs/grim { };
  i3status-rust = super.callPackage ../pkgs/i3status-rust { };
  mako = super.callPackage ../pkgs/mako { };
  my-emacs = super.callPackage ../pkgs/my-emacs { };
  persway = super.callPackage ../pkgs/persway { };
  rust-analyzer = super.callPackage ../pkgs/rust-analyzer { };
  #scdoc = super.callPackage ../pkgs/scdoc { };
  slurp = super.callPackage ../pkgs/slurp { };
  spook = super.callPackage ../pkgs/spook { };
  spotifyd = super.callPackage ../pkgs/spotify { };
  spotnix = super.callPackage ../pkgs/spotnix { };
  wf-recorder = super.callPackage ../pkgs/wf-recorder { };
  wl-clipboard = super.callPackage ../pkgs/wl-clipboard { };
  wl-clipboard-x11 = super.callPackage ../pkgs/wl-clipboard-x11 { };
  wofi = super.callPackage ../pkgs/wofi { };
  xdg-desktop-portal-wlr = super.callPackage ../pkgs/xdg-desktop-portal-wlr { };
}
