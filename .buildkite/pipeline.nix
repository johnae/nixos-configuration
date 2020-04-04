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
  deployImage =
    { projectName
    , runDeploy ? (getEnv "BUILDKITE_BRANCH" == "master")
    , waitForCompletion ? true
    , dependsOn ? [ ]
    , deployDependsOn ? [ ]
    }:
    [
      (run ":pipeline: Build and Push image" {
        key = "${projectName}-docker";
        inherit dependsOn;
        buildNixPath = "shell.nix";
        command = ''
          echo +++ Nix build and push image
          # shellcheck disable=SC2091
          image="$($(build -A pkgs.pushDockerArchive \
                         --arg image \
                         "(import ./default.nix).containers.${projectName}"))"
          nixhash="$(basename "$image" | awk -F'-' '{print $1}')"
          buildkite-agent meta-data set "${projectName}-nixhash" "$nixhash"
        '';
      })
      (when runDeploy
        (
          deploy {
            key = "${projectName}-deploy";
            application = projectName;
            image = "johnae/${projectName}";
            imageTag = "$(buildkite-agent meta-data get '${projectName}-nixhash')";
            inherit waitForCompletion;
            dependsOn = deployDependsOn ++ [ "${projectName}-docker" ];
          }
        ))
    ];

  chunksOf = n: l:
    if length l > 0
    then [ (take n l) ] ++ (chunksOf n (drop n l))
    else [ ];

  onlyDerivations = filterAttrs (_: v: isDerivation v);

  derivationNames = pkgs: attrNames (onlyDerivations pkgs);

  containerNames = derivationNames (import ../default.nix).containers;

  pkgNames = sort (a: b: last (splitString "." a) < last (splitString "." b)) ((
    map (n: "packages.${n}") (derivationNames (import ../default.nix).packages)
  )
  ++ (
    map (n: "containers.${n}") containerNames
  ));

  pkgBatches = chunksOf (length pkgNames / 4 + 1) pkgNames;

  toKeyName = pkgNames: hashString "sha256" (concatStringsSep "-" pkgNames);

  cachePkgs = map (
    pkgs:
    (
      run "Cachix cache ${concatStringsSep " " pkgs} packages" {
        key = "${(toKeyName pkgs)}-cachix";
        command = ''
          nix-shell --run "build -A ${concatStringsSep " -A " pkgs}" | cachix push insane
        '';
      }
    )
  ) pkgBatches;

  cacheStepsKeys = map (pkgs: "${toKeyName pkgs}-cachix") pkgBatches;
in
pipeline [

  cachePkgs
  (
    map
      (
        projectName: deployImage
          (
            {
              inherit projectName;
              dependsOn = cacheStepsKeys;
            }
            //
            (
              if projectName == "buildkite-agent"
              then {
                waitForCompletion = false;
                deployDependsOn =
                  (map
                    (n: "${n}-deploy")
                    (filter (n: n != projectName) containerNames));
              } else { }
            )
          )
      ) containerNames
  )
  (
    run "Build machines" {
      dependsOn = cacheStepsKeys;
      key = "build";
      env = {
        NIX_TEST = "yep"; ## uses dummy metadata
      };
      command = ''
        cachix use nixpkgs-wayland
        nix-shell --run "build -A machines"
      '';
    }
  )
]
