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
let
  PROJECT_NAME = "buildkite-nix";
in
pipeline [
  (
    run ":pipeline: Build and Push image" {
      key = "docker";
      env = { inherit PROJECT_NAME; };
      command = ''
        echo +++ Nix build and import image
        docker load < "$(build -A containers.buildkite \
                          --argstr dockerRegistry "$DOCKER_REGISTRY" \
                          --argstr dockerTag bk-"$BUILDKITE_BUILD_NUMBER")"
        echo +++ Docker push
        docker push "$DOCKER_REGISTRY/$PROJECT_NAME":bk-"$BUILDKITE_BUILD_NUMBER"
      '';
    }
  )
  (
    deploy {
      manifestsPath = "containers/kubernetes/buildkite-agent";
      image = "${DOCKER_REGISTRY}/${PROJECT_NAME}";
      image-tag = "bk-${getEnv "BUILDKITE_BUILD_NUMBER"}";
      waitForCompletion = false;
      dependsOn = [ "docker" ];
    }
  )
]
