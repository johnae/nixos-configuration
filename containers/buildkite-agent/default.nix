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

  passwd = writeText "passwd" ''
    root:x:0:0:System administrator:/root:/bin/bash
    buildkite:x:999:999:Buildkite User:/home/buildkite:/bin/bash
    nixbld1:x:30001:30000:Nix Build User:/var/empty:/bin/nologin
  '';

  group = writeText "group" ''
    root:x:0:
    buildkite:x:999:
    nixbld:x:30000:nixbld1
  '';

  rootfs = stdenv.mkDerivation {
    version = "1";
    name = "rootfs-buildkite";
    buildCommand = ''
      mkdir -p $out/{root,etc/nix,tmp,home/buildkite}
      cp ${nixconf} $out/etc/nix/nix.conf
      cp ${passwd} $out/etc/passwd
      cp ${group} $out/etc/group
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

  extraCommands = ''
    chmod 1777  home/buildkite
    chmod 1777 tmp
    mkdir -p usr/bin
    ln -s ${coreutils}/bin/env usr/bin/env
  '';

  config = {
    Entrypoint = [
      "${tini}/bin/tini"
      "-g"
      "--"
      "${buildkite-latest}/bin/buildkite-agent"
    ];
    Cmd = [ "start" ];
    User = "buildkite";
    Env = [
      "ENV=/etc/profile.d/nix.sh"
      "NIX_PATH=nixpkgs=${pkgs.path}"
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
