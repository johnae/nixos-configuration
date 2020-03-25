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
        nix-shell --run "build -A containers" | cachix push insane
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
        buildkiteDepends="[ "
        for container in containers/*; do
          if [ ! -d "$container" ]; then continue; fi
          if [ "$(basename "$container")" = "buildkite" ]; then continue; fi
          name="$(basename "$container")"
          buildkiteDepends="$buildkiteDepends \"$name-deploy\""
          nix eval -f "$container"/.buildkite/pipeline.nix --argstr name "$name" --json steps \
                     | buildkite-agent pipeline upload --no-interpolation
        done
        buildkiteDepends="$buildkiteDepends \"build\" ]"
        nix eval -f containers/buildkite/.buildkite/pipeline.nix --argstr name "buildkite" --arg dependsOn "$buildkiteDepends" --json steps \
                     | buildkite-agent pipeline upload --no-interpolation
      '';
    }
  )
  (
    run "Build" {
      dependsOn = [
        "cachix"
      ];
      key = "build";
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
