{ stdenv
, writeText
, dockerTools
, nix-plugins
, cacert
, iana-etc
, buildkite-latest
, bashInteractive
, openssh
, coreutils
, gitMinimal
, gnutar
, gzip
, xz
, tini
, pkgs
, dockerRegistry ? "johnae"
, dockerTag ? "latest"
}:
let
  nixconf = writeText "nix.conf" ''
    sandbox = false
    plugin-files = ${nix-plugins}/lib/nix/plugins/libnix-extra-builtins.so
  '';

  rootfs = stdenv.mkDerivation {
    version = "1";
    name = "rootfs-buildkite";
    buildCommand = ''
      mkdir -p $out/{root,etc/nix}
      cp ${nixconf} $out/etc/nix/nix.conf
    '';
  };

  nixImage = import ../nixpkgs-image.nix { inherit pkgs; };
in
dockerTools.buildImage {
  name = "${dockerRegistry}/buildkite-agent";
  tag = dockerTag;
  fromImage = nixImage;
  contents = [
    cacert
    iana-etc
    buildkite-latest
    bashInteractive
    openssh
    coreutils
    gitMinimal
    gnutar
    gzip
    xz
    tini
    rootfs
  ];
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
