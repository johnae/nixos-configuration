## To generate the buildkite json, run this on the command line:
##
## nix-instantiate --eval --strict --json --argstr pipeline "$(pwd)"/.buildkite/pipeline.nix .buildkite | jq .

##
{ cfg, pkgs, lib }:

with builtins;
with lib;
let
  util = import ./util.nix { inherit lib; };

  deployImage =
    with util;
    { projectName
    , runDeploy ? (getEnv "BUILDKITE_BRANCH" == "master")
    , waitForCompletion ? true
    , dependsOn ? [ ]
    , deployDependsOn ? [ ]
    }:
    {
      steps = {
        commands."${projectName}-docker" = {
          inherit dependsOn;
          agents.queue = "linux";
          label = "Build and push docker image for ${projectName}";
          command = withBuildEnv ''
            echo +++ Nix build and push image
            # shellcheck disable=SC2091
            image="$($(build -A pkgs.pushDockerArchive \
                           --arg image \
                           "(import ./default.nix).containers.${projectName}"))"
            nixhash="$(basename "$image" | awk -F'-' '{print $1}')"
            buildkite-agent meta-data set "${projectName}-nixhash" "$nixhash"
          '';
        };
      } // (
        if runDeploy then
          {
            deploys."${projectName}-deploy" = {
              label = "Deploy ${projectName}";
              agents.queue = "linux";
              application = projectName;
              dependsOn = with cfg.steps; deployDependsOn ++ [ commands."${projectName}-docker" ];
            };
          }
        else { }
      );
    };

  deployContainers =
    with util;
    map
      (projectName:
        deployImage ({
          inherit projectName; dependsOn = cachePkgsCmds;
        }
        //
        (
          if projectName == "buildkite-agent"
          then {
            waitForCompletion = false;
            deployDependsOn =
              (map
                (n: "${n}-deploy")
                (filter (n: n != projectName) containerNames)
              );
          } else { }
        ))
      )
      containerNames;

  cachePkgs =
    with util;
    {
      steps.commands = listToAttrs (
        map
          (
            pkgs: (
              {
                name = "${toKeyName pkgs}-cachix";
                value = {
                  agents.queue = "linux";
                  label = "Cache pkgs: ${concatStringsSep " " pkgs}";
                  command = withBuildEnv ''
                    nix-shell --run "build -A ${concatStringsSep " -A " pkgs}" | cachix push insane
                  '';
                };
              }
            )
          )
          pkgBatches
      );
    };

  cachePkgsCmds =
    with cfg.steps;
    mapAttrsToList
      (name: _: commands."${name}")
      cachePkgs.steps.commands;

in
with cfg.steps; with util; {

  imports = [
    (import ./deploys.nix)
    cachePkgs
  ] ++ deployContainers;

  steps = {
    commands.build-machines = {
      agents.queue = "linux";
      label = "Build machines";
      dependsOn = lib.mapAttrsToList (name: _: commands."${name}") cachePkgs.steps.commands;
      env.NIX_TEST = "yep";
      command = withBuildEnv ''
        cachix use nixpkgs-wayland
        nix-shell --run "build -A machines"
      '';
    };
  };
}
