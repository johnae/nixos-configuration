{ stdenv
, writeText
, bashInteractive
, openssh
, gnupg
, sops
, coreutils
, gnugrep
, gnused
, gawk
, cacert
, curl
, git
, git-lfs
, kubectl
, kustomize
, argocd
, argocd-ui
, dockerTools
, dockerRegistry ? "johnae"
, dockerTag ? "latest"
}:
let
  passwd = writeText "passwd" ''
    root:x:0:0:System administrator:/root:/bin/bash
    argocd:x:999:999:ArgoCD User:/home/argocd:/bin/nologin
  '';

  group = writeText "group" ''
    root:x:0:
    argocd:x:999:
  '';

  rootfs = stdenv.mkDerivation {
    version = "1";
    name = "rootfs-argocd";
    buildCommand = ''
      mkdir -p $out/{root,etc/nix,tmp,app/config/ssh,app/config/tls,home/argocd}
      touch $out/app/config/ssh/ssh_known_hosts
      cp ${passwd} $out/etc/passwd
      cp ${group} $out/etc/group
    '';
  };
in
dockerTools.buildLayeredImage {
  name = "${dockerRegistry}/argocd";
  tag = dockerTag;
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
    curl
    git
    git-lfs
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
    ];
  };
}
