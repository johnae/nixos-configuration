{
  allowUnfree = true;
  nix = {
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "insane.cachix.org-1:cLCCoYQKkmEb/M88UIssfg2FiSDUL4PUjYj9tdo4P8o="
    ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://insane.cachix.org"
    ];
  };
}
