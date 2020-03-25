with (import ../../../nix/nixpkgs.nix) {
  overlays = (import ../../../nix/nixpkgs-overlays.nix);
};
stdenv.mkDerivation {
  name = "build";
  buildInputs = with insane-lib; [
    strict-bash
    docker
    kustomize
    jq
  ];
}
