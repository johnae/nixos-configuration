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

      maybeUpdateCargoShas() {
        if nix eval -f default.nix packages."$1".cargoSha256 > /dev/null 2>&1; then
          update-rust-package-cargo "$1"
          gitCommitUpdate "$1 cargo dependencies" || echo no update
        fi
      }

      echo --- Updating packages

      update-k3s
      gitCommitUpdate k3s || echo no update

      update-rust-analyzer
      gitCommitUpdate rust-analyzer || echo no update

      update-buildkite
      gitCommitUpdate buildkite || echo no update

      update-nixos-hardware
      gitCommitUpdate nixos-hardware || echo no update

      for pkg in $(jq -r '. | keys | .[]' nix/sources.json); do
        if [ -d "pkgs/$pkg" ]; then
          niv update "$pkg"
          if gitCommitUpdate "$pkg" || [ "$FORCE_UPDATE" = "yes" ]; then
            maybeUpdateCargoShas "$pkg"
            build -A packages."$pkg" | cachix push insane
          fi
        fi
      done

      ## just because I'm stubborn and want to use the git repo for nixpkgs rather
      ## than the channel... so this hack enables use of command-not-found
      update-programs-sqlite
      gitCommitUpdate programs.sqlite || echo no update

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
