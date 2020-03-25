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
    run "Build subprojects" {
      dependsOn = [
        "cachix"
      ];
      key = "subprojects";
      command = ''
        for container in containers/*; do
          if [ ! -d "$container" ]; then continue; fi
          nix eval -f "$container"/.buildkite/pipeline.nix --argstr name "$(basename "$container")" --json steps \
                   | buildkite-agent pipeline upload --no-interpolation
        done
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
        cachix use nixpkgs-wayland
        nix-shell --run build
      '';
    }
  )
]
