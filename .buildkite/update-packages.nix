## To generate the buildkite json, run this on the command line:
##
## nix-instantiate --eval --strict --json --argstr pipeline "$(pwd)"/.buildkite/update-packages.nix .buildkite | jq .

##
{ cfg, pkgs, lib }:

with builtins;
with lib;
with (import ./util.nix { inherit lib; });
let
  skipPackages = [ ];
in
{
  steps.commands.update-packages = {
    label = "Update packages";
    command = withBuildEnv ''
      echo --- Ensuring proper git configuration
      git config user.name "$BUILDKITE_AGENT_META_DATA_HOSTNAME"
      git config user.email "$USER@$BUILDKITE_AGENT_META_DATA_HOSTNAME"

      remote=origin
      branch="$BUILDKITE_BRANCH"

      echo --- Resetting git repo
      git fetch "$remote" "$branch"
      git checkout "$branch"
      git reset --hard "$remote/$branch"

      echo --- Updating packages
      nix-shell --run update-k3s
      nix-shell --run update-rust-analyzer
      nix-shell --run update-user-nixpkgs

      SKIP="${concatStringsSep " " skipPackages}"
      for change in $(git diff-index --name-only HEAD); do
        pkg="$(echo "$change" | awk -F'/' '{print $2}')"
        for skip in $SKIP; do
          if [ "$skip" = "$pkg" ]; then
            echo --- Skipping package "$pkg" because of skiplist
            git checkout "pkgs/$pkg"
          fi
        done
      done
      for change in $(git diff-index --name-only HEAD); do
        pkg="$(echo "$change" | awk -F'/' '{print $2}')"
        git add "pkgs/$pkg"
        if ! git diff --quiet --staged --exit-code; then
          echo --- Building and caching pkg "pkgs/$pkg"
          git diff --staged
          nix-shell --run "build -A packages.$pkg" | cachix push insane
          echo --- Committing changes to pkg "pkgs/$pkg"
          git commit -m "Auto updated $pkg"
        fi
      done

      echo --- Updating home-manager
      nix-shell --run update-home-manager
      echo --- Updating nixos-hardware
      nix-shell --run update-nixos-hardware
      echo --- Updating overlays
      nix-shell --run update-overlays
      echo --- Updating nixos
      nix-shell --run update-nixos

      for change in $(git diff-index HEAD | awk '{print $NF}'); do
        pkg="$(basename "$change" .json)"

        git add "$change"
        if ! git diff --quiet --staged --exit-code; then
          echo --- Committing changes to "$pkg"
          git diff --staged
          git commit -m "Auto updated $pkg"
        fi
      done

      echo --- Current revisions
      echo "local: $(git rev-parse HEAD)"
      echo "remote: $(git rev-parse "$remote/$branch")"

      LATEST="$(git rev-parse HEAD)"
      if ! git branch -r --contains "$LATEST" 2> /dev/null | grep -q "origin/master"; then
        echo --- Pushing to origin
        git push "$remote" "$branch"
      else
        echo --- Nothing to push
      fi

    '';
  };
}
