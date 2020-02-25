let
  nixpkgs = import ./nixpkgs.nix;
  pkgs = nixpkgs {};
  lib = pkgs.lib;

  nixosFunc = import (pkgs.path + "/nixos");

  buildConfig = configuration:
    (nixosFunc { inherit configuration; }).system;

  buildIso = config:
    with builtins;
    let
      metadataDir = toString ./metadata;
      confName = (baseNameOf (dirOf config));
      isoConf =
        let
          conf = "${metadataDir}/${confName}/isoconf.json";
        in
          if pathExists conf then fromJSON (extraBuiltins.sops conf) else {};
      system-closure = buildConfig config;
      configuration = {
        imports = [
          (pkgs.path + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          (pkgs.path + "/nixpkgs/nixos/modules/installer/cd-dvd/channel.nix")
        ];

        environment.etc = {
          "install.sh" = {
            source = ./install.sh;
            mode = "0700";
          };
          "system-closure-path" = {
            text = toString system-closure;
          };
        };

        isoImage.storeContents = [ system-closure ];

        environment.etc."profile.local".text = ''
          echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
          sleep 15
          if ! ping -c 1 www.google.com; then
              cat<<EOF
          No network - please set it up, then exit the shell to continue.
          For example, on a laptop, you might want to run something like:

          wpa_supplicant -B -i INTERFACE -c <(wpa_passphrase 'NETWORK' 'PASSWORD')

          EOF
              bash
          fi

          ${lib.concatMapStringsSep "\n"
          (s: "export ${s}")
          (lib.mapAttrsToList (name: value: "${name}=\"${value}\"") isoConf)}

          sudo --preserve-env=DISK_PASSWORD,ADDITIONAL_VOLUMES,ADDITIONAL_DISK \
                /etc/install.sh

          echo Rebooting in 10 seconds
          sleep 10
          sudo shutdown -h now
        '';
      };
    in
      (nixosFunc { inherit configuration; }).config.system.build.isoImage;
in
rec {
  machines = pkgs.recurseIntoAttrs {
    europa = buildConfig ./machines/europa/configuration.nix;
    phobos = buildConfig ./machines/phobos/configuration.nix;
    rhea = buildConfig ./machines/rhea/configuration.nix;
    titan = buildConfig ./machines/titan/configuration.nix;
    hyperion = buildConfig ./machines/hyperion/configuration.nix;
  };
  packages =
    let
      pkgs = nixpkgs {
        overlays = [
          (import ./overlays/pkgs.nix)
          (import ./overlays/emacs-overlay.nix)
        ];
      };
    in with pkgs;
    pkgs.recurseIntoAttrs {
      inherit alacritty nushell sway swaybg
        swayidle swaylock swaylock-dope blur emacsGit-nox
        mako spotifyd netns-exec spotnix persway lorri
        wl-clipboard wl-clipboard-x11 wf-recorder
        nixpkgs-fmt i3status-rust rust-analyzer-bin;
    };
  installers = {
    europa = buildIso ./machines/europa/configuration.nix;
    phobos = buildIso ./machines/phobos/configuration.nix;
    rhea = buildIso ./machines/rhea/configuration.nix;
    titan = buildIso ./machines/titan/configuration.nix;
    hyperion = buildIso ./machines/hyperion/configuration.nix;
  };
}
