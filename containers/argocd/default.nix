{ stdenv
, writeText
, bashInteractive
, nix-plugins
, openssh
, gnupg
, sops
, coreutils
, gnugrep
, gnused
, gawk
, cacert
, gitMinimal
, kubectl
, kustomize
, argocd
, argocd-ui
, sudo
, busybox
, dockerTools
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
    argocd:x:999:999:ArgoCD User:/home/argocd:/bin/bash
    nixbld1:x:30001:30000:Nix Build User:/var/empty:/bin/nologin
  '';

  group = writeText "group" ''
    root:x:0:
    argocd:x:999:
    nixbld:x:30000:nixbld1
  '';

  rootfs = stdenv.mkDerivation {
    version = "1";
    name = "rootfs-argocd";
    buildCommand = ''
      mkdir -p $out/{root,etc/nix,tmp,app/config/ssh,app/config/tls,home/argocd}
      touch $out/app/config/ssh/ssh_known_hosts
      cp ${nixconf} $out/etc/nix/nix.conf
      cp ${passwd} $out/etc/passwd
      cp ${group} $out/etc/group
    '';
  };

  nixImage = import ../nixpkgs-image.nix { inherit pkgs; };
in
dockerTools.buildImage {
  name = "${dockerRegistry}/argocd";
  tag = dockerTag;
  fromImage = nixImage;
  contents = [
    bashInteractive
    openssh
    gnupg
    sops
    coreutils
    gnugrep
    gnused
    gawk
    cacert
    gitMinimal
    kubectl
    kustomize
    argocd
    argocd-ui
    rootfs
  ];

  extraCommands = ''
    chmod 1777  home/argocd
    chmod 1777 tmp
    mkdir -p usr/bin
    ln -s ${coreutils}/bin/env usr/bin/env
  '';

  config = {
    Entrypoint = [ "${bashInteractive}/bin/bash" ];
    WorkingDir = "/home/argocd";
    User = "argocd";
    Env = [
      "USER=argocd"
      "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
      "PAGER=cat"
      "ENV=/etc/profile.d/nix.sh"
      "NIX_PATH=nixpkgs=${pkgs.path}"
      "PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
      "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    ];
    Volumes = {
      "/nix" = { };
    };
  };
}
