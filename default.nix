let
  pkgs = import ./nix { };
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
          conf = "${metadataDir}/${confName}/isoconf.yaml";
        in
        if pathExists conf then extraBuiltins.sops conf else { };
      system-closure = buildConfig config;
      configuration = {
        imports = [
          (pkgs.path + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          (pkgs.path + "/nixos/modules/installer/cd-dvd/channel.nix")
        ];

        environment.etc = {
          "install.sh" = {
            source = ./installer/install.sh;
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
              sudo bash
          fi

          ${lib.concatMapStringsSep "\n"
            (s: "export ${s}")
            (lib.mapAttrsToList (name: value: "${name}=\"${value}\"") isoConf)}

          sudo --preserve-env=DISK_PASSWORD,ADDITIONAL_VOLUMES,ADDITIONAL_DISK \
                /etc/install.sh

          echo Rebooting in 5 seconds
          sleep 5
          sudo shutdown -h now
        '';
      };
    in
    (nixosFunc { inherit configuration; }).config.system.build.isoImage;
in
rec {
  inherit pkgs;
  machines = pkgs.recurseIntoAttrs {
    europa = buildConfig ./machines/europa/configuration.nix;
    phobos = buildConfig ./machines/phobos/configuration.nix;
    rhea = buildConfig ./machines/rhea/configuration.nix;
    titan = buildConfig ./machines/titan/configuration.nix;
    hyperion = buildConfig ./machines/hyperion/configuration.nix;
    altair = buildConfig ./machines/altair/configuration.nix;
  };
  containers = pkgs.recurseIntoAttrs {
    buildkite-agent = pkgs.callPackage ./containers/buildkite-agent { };
    btrfs-backups = pkgs.callPackage ./containers/btrfs-backups { };
    ssh-forwarder = pkgs.callPackage ./containers/ssh-forwarder { };
    argocd = pkgs.callPackage ./containers/argocd { };
  };
  packages =
    let
      toCache =
        lib.mapAttrs'
          (
            name: _: lib.nameValuePair name pkgs."${name}"
          )
          (
            lib.filterAttrs
              (name: type: type == "directory")
              (builtins.readDir ./pkgs)
          );
    in
    with pkgs;
    pkgs.recurseIntoAttrs (toCache // {
      #inherit gnupg mesa-iris;
    });
  installers = {
    europa = buildIso ./machines/europa/configuration.nix;
    phobos = buildIso ./machines/phobos/configuration.nix;
    rhea = buildIso ./machines/rhea/configuration.nix;
    titan = buildIso ./machines/titan/configuration.nix;
    hyperion = buildIso ./machines/hyperion/configuration.nix;
    altair = buildIso ./machines/altair/configuration.nix;
  };
}
