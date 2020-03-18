## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with (import ../nix/nixpkgs.nix) {
  overlays = (import ../nix/nixpkgs-overlays.nix);
};
with builtins;
with lib;
with buildkite;

pipeline [
  (
    run "Cachix cache" {
      key = "cachix";
      command = ''
        nix-shell --run "build -A packages" | cachix push insane
      '';
    }
  )
  (
    run "Build" {
      dependsOn = [
        "cachix"
      ];
      env = {
        NIX_TEST = "yep"; ## uses dummy metadata
      };
      command = ''
        nix-shell --run build
      '';
    }
  )
]
