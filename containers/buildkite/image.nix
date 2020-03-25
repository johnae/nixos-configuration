{ dockerRegistry ? "johnae", dockerTag ? "latest" }:
let
  pkgs = import ../../nix { };
  paths = with pkgs; [
    buildkite-latest
    bashInteractive
    openssh
    coreutils
    gitMinimal
    gnutar
    gzip
    xz
    tini
    cacert
  ];

  nixconf = pkgs.writeText "nix.conf" ''
    sandbox = false
    plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins/libnix-extra-builtins.so
  '';

  rootfs = pkgs.stdenv.mkDerivation {
    version = "1";
    name = "rootfs-buildkite";
    buildCommand = ''
      mkdir -p $out/{root,etc/nix}
      cp ${nixconf} $out/etc/nix/nix.conf
    '';
  };

  nixImage = import ../nixpkgs-image.nix { inherit pkgs; };
in
  with pkgs; dockerTools.buildImage {
    name = "${dockerRegistry}/buildkite-nix";
    tag = dockerTag;
    fromImage = nixImage;
    contents = paths ++ [ cacert iana-etc rootfs ];
    config = {
      Entrypoint = [
        "${tini}/bin/tini"
        "-g"
        "--"
        "${buildkite-latest}/bin/buildkite-agent"
      ];
      Cmd = [ "start" ];
      Env = [
        "ENV=/etc/profile.d/nix.sh"
        "NIX_PATH=nixpkgs=channel:nixpkgs-unstable"
        "PAGER=cat"
        "PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
        "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "BUILDKITE_PLUGINS_PATH=/var/lib/buildkite/plugins"
        "BUILDKITE_BUILD_PATH=/var/lib/buildkite/builds"
      ];
      Volumes = {
        "/nix" = { };
      };
    };
  }
