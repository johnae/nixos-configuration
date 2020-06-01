self: super:
rec {

  pushDockerArchive = with self.lib; with builtins; { image, tag ? null }:
    let
      imageTag = if tag != null then tag else head (splitString "-" (baseNameOf "${image}"));
    in
    self.writeStrictShellScript "pushDockerArchive" ''
      echo pushing ${image.imageName}:${imageTag} 1>&2
      ${self.skopeo}/bin/skopeo copy "$@" \
          docker-archive:${image} \
          docker://${image.imageName}:${imageTag} 1>&2
      echo ${image}
    '';

  k3s = super.callPackage ../pkgs/k3s { };
  system-san-francisco-font = super.callPackage ../pkgs/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../pkgs/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../pkgs/office-code-pro-font { };
  btr-snap = super.callPackage ../pkgs/btr-snap { };

  netns-dbus-proxy = super.callPackage ../pkgs/netns-dbus-proxy { };
  nixpkgs-fmt = super.callPackage ../pkgs/nixpkgs-fmt { };
  sway-unwrapped = super.callPackage ../pkgs/sway { };
  sway = super.callPackage
    (self.path + "/pkgs/applications/window-managers/sway/wrapper.nix") { };
  swaybg = super.callPackage ../pkgs/swaybg { };
  swayidle = super.callPackage ../pkgs/swayidle { };
  swaylock = super.callPackage ../pkgs/swaylock { };
  swaylock-dope = super.callPackage ../pkgs/swaylock-dope { };
  blur = super.callPackage ../pkgs/blur { };
  wlroots = super.callPackage ../pkgs/wlroots { };
  alacritty = super.callPackage ../pkgs/alacritty { };
  fire = super.callPackage ../pkgs/fire { };
  grim = super.callPackage ../pkgs/grim { };
  i3status-rust = super.callPackage ../pkgs/i3status-rust { };
  mako = super.callPackage ../pkgs/mako { };
  my-emacs = super.callPackage ../pkgs/my-emacs { };
  persway = super.callPackage ../pkgs/persway { };
  rust-analyzer-bin = super.callPackage ../pkgs/rust-analyzer-bin { };
  slurp = super.callPackage ../pkgs/slurp { };
  spook = super.callPackage ../pkgs/spook { };
  spotifyd = super.callPackage ../pkgs/spotifyd { };
  spotnix = super.callPackage ../pkgs/spotnix { };
  netns-exec = super.callPackage ../pkgs/netns-exec { };
  wf-recorder = super.callPackage ../pkgs/wf-recorder { };
  wl-clipboard = super.callPackage ../pkgs/wl-clipboard { };
  wl-clipboard-x11 = super.callPackage ../pkgs/wl-clipboard-x11 { };
  xdg-desktop-portal-wlr = super.callPackage ../pkgs/xdg-desktop-portal-wlr { };

  mesa-iris = (super.mesa.override {
    galliumDrivers = [ "nouveau" "virgl" "swrast" "iris" ];
  });

  mynerdfonts = super.callPackage ../pkgs/mynerdfonts {
    fonts = [ "JetBrainsMono" "DroidSansMono" ];
  };

  argocd = super.callPackage ../pkgs/argocd { };

  wayvnc = super.callPackage ../pkgs/wayvnc { };
  aml = super.callPackage ../pkgs/aml { };
  neatvnc = super.callPackage ../pkgs/neatvnc { };

  argocd-ui = super.callPackage ../pkgs/argocd-ui { };

  pipewire = super.callPackage ../pkgs/pipewire { };

  insane = super.recurseIntoAttrs (super.callPackage ../pkgs/insane { });
  inherit (insane) insane-lib buildkite;

  buildkite-latest = super.callPackage ../pkgs/buildkite { };

  scripts = super.recurseIntoAttrs (super.callPackage ../pkgs/strictShellScript.nix { });
  inherit (scripts)
    writeStrictShellScript writeStrictShellScriptBin mkStrictShellScript;

  initialize-user = super.callPackage ../pkgs/initialize-user.nix { };

  inherit ((super.callPackage ../pkgs/scripts { }).paths)
    mail project-select launch git-credential-pass sk-sk
    sk-run sk-window sk-passmenu browse-chromium
    screenshot random-name add-wifi-network update-wifi-networks
    update-wireguard-keys spotify-play-album spotify-play-track spotify-cmd
    spotify-play-artist spotify-play-playlist btrfs-diff
    ;
}
