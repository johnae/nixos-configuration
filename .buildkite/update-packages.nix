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

        git fetch "$remote" "$branch"
        git checkout "$branch"
        git reset --hard "$remote/$branch"

        nix-shell --run update-k3s
        nix-shell --run update-user-nixpkgs
        nix-shell --run update-rust-analyzer

        for change in $(git diff-index HEAD | awk '{print $NF}'); do
          pkg="$(echo "$change" | awk -F'/' '{print $2}')"
          echo --- Committing changes to pkg "pkgs/$pkg"
          git add "pkgs/$pkg"
          git commit -m "Auto updated $pkg"
        done

        nix-shell --run update-home-manager
        nix-shell --run update-nixos-hardware

        for change in $(git diff-index HEAD | awk '{print $NF}'); do
          pkg="$(basename change .json)"
          echo --- Committing changes to "$pkg"
          git add "$change"
          git commit -m "Auto updated $pkg"
        done
      '';
    }
  )

]
