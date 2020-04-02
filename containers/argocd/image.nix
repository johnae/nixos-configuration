{ dockerRegistry ? "johnae", dockerTag ? "latest" }:
let
  pkgs = import ../../nix { };
  lib = pkgs.lib;

  passwd = pkgs.writeText "passwd" ''
    root:x:0:0:System administrator:/root:/bin/bash
    argocd:x:999:999:ArgoCD User:/home/argocd:/bin/nologin
  '';

  group = pkgs.writeText "group" ''
    root:x:0:
    argocd:x:999:
  '';

  rootfs = pkgs.stdenv.mkDerivation {
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
pkgs.dockerTools.buildLayeredImage {
  name = "${dockerRegistry}/argocd";
  tag = dockerTag;
  contents = with pkgs; [
    utillinux
    bashInteractive
    openssh
    gnupg
    sops
    coreutils
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
  '';

  config = {
    Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];
    WorkingDir = "/home/argocd";
    User = "argocd";
  };
}
