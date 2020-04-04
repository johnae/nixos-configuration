{ name, runDeploy ? false, dependsOn ? [ ] }:
## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --argstr name somename --json steps

with (import ../../../nix/nixpkgs.nix) {
  overlays = (import ../../../nix/nixpkgs-overlays.nix);
};
with builtins;
with lib;
with buildkite;
let
  PROJECT_NAME = "argocd";
in
pipeline [
  (run ":pipeline: Build and Push image" {
    key = "${name}-docker";
    inherit dependsOn;
    buildNixPath = "shell.nix";
    command = ''
      echo +++ Nix build and push image
      # shellcheck disable=SC2091
      image="$($(build -A pkgs.pushDockerArchive \
                     --arg image \
                     "(import ./default.nix).containers.${PROJECT_NAME}"))"
      nixhash="$(basename "$image" | awk -F'-' '{print $1}')"
      buildkite-agent meta-data set "${name}-nixhash" "$nixhash"
    '';
  })
  (when runDeploy
    (
      deploy {
        key = "${name}-deploy";
        application = "argocd";
        image = "${DOCKER_REGISTRY}/${PROJECT_NAME}";
        imageTag = "$(buildkite-agent meta-data get '${name}-nixhash')";
        dependsOn = dependsOn ++ [ "${name}-docker" ];
      }
    ))
]
