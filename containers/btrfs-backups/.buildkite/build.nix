with (import ../../../nix/nixpkgs.nix) {
  overlays = (import ../../../nix/nixpkgs-overlays.nix);
};
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
