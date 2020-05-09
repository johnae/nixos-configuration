{
  allowUnfree = true;
  nix = {
    binaryCachePublicKeys = [
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "insane.cachix.org-1:cLCCoYQKkmEb/M88UIssfg2FiSDUL4PUjYj9tdo4P8o="
    ];
    binaryCaches = [
      "https://nixpkgs-wayland.cachix.org"
      "https://insane.cachix.org"
    ];
  };
}
