## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with import <insanepkgs> {};
with builtins;
with lib;
with buildkite;

pipeline [
  (
    run "Cachix cache" {
      command = ''
        ./build.sh -A packages | cachix push insane
      '';
    })

]
