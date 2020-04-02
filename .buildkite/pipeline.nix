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
  runDeployArg =
    if getEnv "BUILDKITE_BRANCH" == "master"
    then "--arg runDeploy \"true\"" else "";

  chunksOf = n: l:
    if length l > 0
    then [ (take n l) ] ++ (chunksOf n (drop n l))
    else [ ];

  onlyDerivations = filterAttrs (_: v: isDerivation v);

  derivationNames = pkgs: attrNames (onlyDerivations pkgs);

  pkgNames = sort (a: b: last (splitString "." a) < last (splitString "." b)) ((
    map (n: "packages.${n}") (derivationNames (import ../default.nix).packages)
  )
  ++ (
    map (n: "containers.${n}") (derivationNames (import ../default.nix).containers)
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
    run "Build subprojects" {
      dependsOn = cacheStepsKeys;
      key = "subprojects";
      command = ''
        buildkiteDepends="[ "
        for container in containers/*; do
          if [ ! -d "$container" ]; then continue; fi
          if [ "$(basename "$container")" = "buildkite" ]; then continue; fi
          name="$(basename "$container")"
          buildkiteDepends="$buildkiteDepends \"$name-deploy\""
          nix eval -f "$container"/.buildkite/pipeline.nix ${runDeployArg} --argstr name "$name" --json steps \
                     | buildkite-agent pipeline upload --no-interpolation
        done
        buildkiteDepends="$buildkiteDepends \"build\" ]"
        nix eval -f containers/buildkite/.buildkite/pipeline.nix ${runDeployArg} --argstr name "buildkite" --arg dependsOn "$buildkiteDepends" --json steps \
                     | buildkite-agent pipeline upload --no-interpolation
      '';
    }
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
