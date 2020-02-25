self: super:
let
  importFromGithubMeta = with builtins;
    path:
    import (super.fetchFromGitHub (fromJSON (readFile path)));
in
rec {

  toIgnoreOptions = ignore: super.lib.concatStringsSep " "
    (map (option: "--ignore=${option}") ignore);

  firejailed = { package, ignore ? [] }: super.stdenv.mkDerivation {
    name = "firejail-wrapped-${package.name}";
    buildCommand = ''
      mkdir -p $out/bin
      for bin in ${package}/bin/*; do
      cat <<_EOF >$out/bin/"$(basename "$bin")"
      #!${super.stdenv.shell} -e
      /run/wrappers/bin/firejail ${toIgnoreOptions ignore} "$bin" "\$@"
      _EOF
      chmod 0755 $out/bin/"$(basename "$bin")"
      done
    '';
    meta = {
      description = "Jailed ${package.name}";
    };
  };

  k3s = super.callPackage ../pkgs/k3s {};
  system-san-francisco-font = super.callPackage ../pkgs/system-san-francisco-font {};
  san-francisco-mono-font = super.callPackage ../pkgs/san-francisco-mono-font {};
  office-code-pro-font = super.callPackage ../pkgs/office-code-pro-font {};
  btr-snap = super.callPackage ../pkgs/btr-snap {};
  lorri = importFromGithubMeta ./lorri.json {};

  netns-dbus-proxy = super.callPackage ../pkgs/netns-dbus-proxy {};
  nushell = super.callPackage ../pkgs/nushell {};
  nixpkgs-fmt = super.callPackage ../pkgs/nixpkgs-fmt {};
  sway-unwrapped = super.callPackage ../pkgs/sway {};
  sway = super.callPackage
    (self.path + "/pkgs/applications/window-managers/sway/wrapper.nix") {};
  swaybg = super.callPackage ../pkgs/swaybg {};
  swayidle = super.callPackage ../pkgs/swayidle {};
  swaylock = super.callPackage ../pkgs/swaylock {};
  swaylock-dope = super.callPackage ../pkgs/swaylock-dope {};
  blur = super.callPackage ../pkgs/blur {};
  wlroots = super.callPackage ../pkgs/wlroots {};
  alacritty = super.callPackage ../pkgs/alacritty {};
  fire = super.callPackage ../pkgs/fire {};
  grim = super.callPackage ../pkgs/grim {};
  i3status-rust = super.callPackage ../pkgs/i3status-rust {};
  mako = super.callPackage ../pkgs/mako {};
  my-emacs = super.callPackage ../pkgs/my-emacs {};
  persway = super.callPackage ../pkgs/persway {};
  rust-analyzer-bin = super.callPackage ../pkgs/rust-analyzer-bin {};
  slurp = super.callPackage ../pkgs/slurp {};
  spook = super.callPackage ../pkgs/spook {};
  spotifyd = super.callPackage ../pkgs/spotifyd {};
  spotnix = super.callPackage ../pkgs/spotnix {};
  netns-exec = super.callPackage ../pkgs/netns-exec {};
  wf-recorder = super.callPackage ../pkgs/wf-recorder {};
  wl-clipboard = super.callPackage ../pkgs/wl-clipboard {};
  wl-clipboard-x11 = super.callPackage ../pkgs/wl-clipboard-x11 {};
  xdg-desktop-portal-wlr = super.callPackage ../pkgs/xdg-desktop-portal-wlr {};

  fish-kubectl-completions = super.callPackage ../pkgs/fish-kubectl-completions {};
  google-cloud-sdk-fish-completion = super.callPackage ../pkgs/google-cloud-sdk-fish-completion {};

  inherit (super.callPackage ../pkgs/strictShellScript.nix {})
    writeStrictShellScript writeStrictShellScriptBin mkStrictShellScript
    ;

  initInstall = super.callPackage ../pkgs/initInstall.nix {};

  inherit ((super.callPackage ../pkgs/scripts {}).paths)
    edit edi emacs-run emacs-server mail project-select launch
    git-credential-pass sk-sk sk-run sk-window sk-passmenu browse-chromium
    screenshot random-name add-wifi-network update-wifi-networks
    update-wireguard-keys spotify-play-album spotify-play-track spotify-cmd
    spotify-play-artist spotify-play-playlist
    ;
}
