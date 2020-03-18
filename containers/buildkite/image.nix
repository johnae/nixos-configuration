{ dockerRegistry, dockerTag ? "latest" }:
let
  pkgs = (import ../../nix/nixpkgs.nix) {
    overlays = (import ../../nix/nixpkgs-overlays.nix);
  };
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

  nixImage = import ../nixpkgs-image.nix { inherit pkgs; };
in
  with pkgs; dockerTools.buildImage {
    name = "${dockerRegistry}/buildkite-nix";
    tag = dockerTag;
    fromImage = nixImage;
    contents = paths ++ [ cacert iana-etc ./rootfs ];
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
