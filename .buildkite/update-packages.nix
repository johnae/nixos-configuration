## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with import <insanepkgs> {};
with builtins;
with lib;
with buildkite;
let
  skipPackages = [ "wlroots" ];
in
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
        nix-shell --run update-k3s
        nix-shell --run update-rust-analyzer
        nix-shell --run update-user-nixpkgs

        SKIP="${concatStringsSep " " skipPackages}"
        for change in $(git diff-index --name-only HEAD); do
          pkg="$(echo "$change" | awk -F'/' '{print $2}')"
          for skip in $SKIP; do
            if [ "$skip" = "$pkg" ]; then
              echo Skipping package "$pkg" because of skiplist
              git checkout "pkgs/$pkg"
            fi
          done
        done
        for change in $(git diff-index --name-only HEAD); do
          pkg="$(echo "$change" | awk -F'/' '{print $2}')"
          git add "pkgs/$pkg"
          if ! git diff --quiet --staged --exit-code; then
            echo --- Committing changes to pkg "pkgs/$pkg"
            git diff --staged
            ./build.sh -A packages."$pkg" | cachix push insane
            git commit -m "Auto updated $pkg"
          fi
        done

        nix-shell --run update-home-manager
        nix-shell --run update-nixos-hardware

        for change in $(git diff-index HEAD | awk '{print $NF}'); do
          pkg="$(basename "$change" .json)"

          git add "$change"
          if ! git diff --quiet --staged --exit-code; then
            echo --- Committing changes to "$pkg"
            git diff --staged
            git commit -m "Auto updated $pkg"
          fi
        done
      '';
    }
  )

]
