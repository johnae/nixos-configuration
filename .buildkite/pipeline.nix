## To generate the buildkite json, run this on the command line:
##
## nix-instantiate --eval --strict --json --argstr pipeline "$(pwd)"/.buildkite/pipeline.nix .buildkite | jq .

##
{ cfg, pkgs, lib }:

with builtins;
with lib;
with (import ./util { inherit lib; });
let
  containersToDeploy = filter (v: v != "argocd" && v != "buildkite-agent") containerNames;
  deployContainers =
    {
      steps.deploys = listToAttrs (
        map
          (
            name:
            {
              inherit name;
              value = {
                agents.queue = "linux";
                dependsOn = keysOf cachePkgs.steps.commands;
              };
            }
          )
          containersToDeploy
      );
    };

  cachePkgs =
    {
      steps.commands = listToAttrs (
        map
          (
            pkgs: (
              {
                name = "${toKeyName pkgs}-cachix";
                value = {
                  agents.queue = "linux";
                  label = ":nix: Cache pkgs: ${concatStringsSep " " pkgs}";
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

  ## this exists because we must refer to what is
  ## actually in config
  keysOf = attr:
    with cfg.steps;
    mapAttrsToList
      (name: _: commands."${name}")
      attr;

in
{

  imports = [
    (import ./modules/deploys.nix)
    cachePkgs
    deployContainers
  ];

  steps = with cfg.steps; {

    deploys.argocd = {
      agents.queue = "linux";
      #runDeploy = false; ## do this manually for now
      dependsOn = keysOf cachePkgs.steps.commands;
    };

    deploys.buildkite-agent = {
      agents.queue = "linux";
      waitForCompletion = false;
      dependsOn = (keysOf cachePkgs.steps.commands);
      deployDependsOn = (keysOf deployContainers.steps.deploys) ++ [ cfg.steps.deploys.argocd ];
    };

    commands.build-machines = {
      agents.queue = "linux";
      label = ":nix: Build machines";
      dependsOn = keysOf cachePkgs.steps.commands;
      env.NIX_TEST = "yep"; ## uses dummy secrets
      command = withBuildEnv ''
        cachix use nixpkgs-wayland
        nix-shell --run "build -A machines"
      '';
    };
  };
}
