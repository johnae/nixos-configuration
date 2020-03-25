## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with (import ../../../nix/nixpkgs.nix) {
  overlays = (import ../../../nix/nixpkgs-overlays.nix);
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
        image="$(nix-shell --run strict-bash <<'SH'
                  build -A containers.buildkite \
                        --argstr dockerRegistry "${DOCKER_REGISTRY}" \
                        --argstr dockerTag latest
        SH
        )"
        docker load < "$image"

        nixhash="$(basename "$image" | awk -F'-' '{print $1}')"

        buildkite-agent meta-data set "nixhash" "$nixhash"

        docker tag \
          "${DOCKER_REGISTRY}/${PROJECT_NAME}:latest" \
          "${DOCKER_REGISTRY}/${PROJECT_NAME}:$nixhash"

        echo +++ Docker push
        docker push "${DOCKER_REGISTRY}/${PROJECT_NAME}:$nixhash"
      '';
    }
  )
  (
    deploy {
      manifestsPath = "containers/buildkite/kubernetes";
      image = "${DOCKER_REGISTRY}/${PROJECT_NAME}";
      imageTag = "$(buildkite-agent meta-data get 'nixhash')";
      waitForCompletion = false;
      dependsOn = [ "docker" ];
    }
  )
]
