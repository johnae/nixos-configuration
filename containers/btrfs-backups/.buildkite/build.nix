with import <insanepkgs> {};
with pkgs;
stdenv.mkDerivation {
  name = "build";
  buildInputs = [
    insane-lib.strict-bash
    docker
    kustomize
    kubectl
  ];
}
