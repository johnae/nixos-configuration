## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with import <insanepkgs> {};
with builtins;
with lib;
with buildkite;

pipeline [

  (
    run "Update packages" {
      command = ''

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
        nix-shell --run update-k3s 2>/dev/null
        nix-shell --run update-user-nixpkgs 2>/dev/null
        nix-shell --run update-rust-analyzer 2>/dev/null

        for change in $(git diff-index --name-only HEAD); do
          pkg="$(echo "$change" | awk -F'/' '{print $2}')"
          git add "pkgs/$pkg"
          if ! git diff --staged --exit-code; then
            echo --- Committing changes to pkg "pkgs/$pkg"
            git commit -m "Auto updated $pkg"
          fi
        done

        nix-shell --run update-home-manager 2>/dev/null
        nix-shell --run update-nixos-hardware 2>/dev/null

        for change in $(git diff-index HEAD | awk '{print $NF}'); do
          pkg="$(basename "$change" .json)"

          git add "$change"
          if ! git diff --staged --exit-code; then
            echo --- Committing changes to "$pkg"
            git commit -m "Auto updated $pkg"
          fi
        done
      '';
    }
  )

]
