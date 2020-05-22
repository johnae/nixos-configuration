## To generate the buildkite json, run this on the command line:
##
## nix-instantiate --eval --strict --json --argstr pipeline "$(pwd)"/.buildkite/update-packages.nix .buildkite | jq .

##
{ cfg, pkgs, lib }:

with builtins;
with lib;
with (import ./util { inherit lib; });
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
      nix-shell --run "niv update"
      nix-shell --run update-nixos-hardware
      nix-shell --run "build -A packages" | cachix push insane
      git add nix
      git commit -m "Automatic update"

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
