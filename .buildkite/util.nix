{ lib }:

with builtins;
with lib;

rec {
  withBuildEnv = cmd: ''
    nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
    ${cmd}
    NIXSH
  '';

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
}
