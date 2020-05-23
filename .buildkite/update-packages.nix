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

      gitCommitUpdate() {
        for change in $(git diff-index HEAD | awk '{print $NF}'); do
          git add "$change"
          if ! git diff --quiet --staged --exit-code; then
            echo --- Committing changes to "$1"
            git diff --staged
            git commit -m "Auto updated $1"
            return 0
          fi
        done
        return 1
      }

      echo --- Updating packages

      nix-shell --run update-k3s
      gitCommitUpdate k3s

      nix-shell --run update-rust-analyzer
      gitCommitUpdate rust-analyzer

      nix-shell --run update-buildkite
      gitCommitUpdate buildkite

      nix-shell --run update-nixos-hardware
      gitCommitUpdate nixos-hardware

      for pkg in $(jq -r '. | keys | .[]' nix/sources.json); do
        if [ -d "pkgs/$pkg" ]; then
          niv update "$pkg"
          if gitCommitUpdate "$pkg"; then
            if nix eval -f default.nix packages."$pkg".cargoSha256 2>&1 > /dev/null; then
              nix-shell --run "update-rust-package-cargo '$pkg'"
              gitCommitUpdate "$pkg cargo dependencies"
            fi
            nix-shell --run "build -A packages.$pkg" | cachix push insane
          fi
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
