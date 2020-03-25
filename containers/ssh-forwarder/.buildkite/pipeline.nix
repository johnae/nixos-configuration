{ name }:
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
  PROJECT_NAME = "ssh-forwarder";
  buildNixPath = "containers/ssh-forwarder/.buildkite/build.nix";
in
pipeline [
  (
    (run ":pipeline: Build and Push image" {
      key = "${name}-docker";
      inherit buildNixPath;
      command = ''
        echo +++ Nix build and import image
        image="$(nix-shell --run strict-bash <<'SH'
                  build -A containers.ssh-forwarder \
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
    })
  )
  (
    deploy {
      inherit buildNixPath;
      application = "ssh-forwarder";
      manifestsPath = "containers/ssh-forwarder/kubernetes";
      image = "${DOCKER_REGISTRY}/${PROJECT_NAME}";
      imageTag = "$(buildkite-agent meta-data get 'nixhash')";
      dependsOn = [ "${name}-docker" ];
    }
  )
]
