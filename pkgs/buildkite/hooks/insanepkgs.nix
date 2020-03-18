with import <nixpkgs> { };
let
  fetch-insanepkgs = writeShellScriptBin "fetch-insanepkgs" ''
    set -euo pipefail

    if [ -z "$GITHUB_USER" ]; then
      echo Please set the GITHUB_USER environment variable
      exit 1
    fi
    if [ -z "$GITHUB_TOKEN" ]; then
      echo Please set the GITHUB_TOKEN environment variable
      exit 1
    fi
    if [ -z "$INSANEPKGS_REF" ]; then
      cat <<EOF
      INSANEPKGS_REF env var not set, please set it to a tag, branch
      or commit in the https://github.com/johnae/nixos-configuration repository.
    EOF
      exit 1
    fi

    commit="$(${pkgs.curl}/bin/curl -s --fail -S -u "$GITHUB_USER":"$GITHUB_TOKEN" \
                https://api.github.com/repos/johnae/nixos-configuration/commits/"$INSANEPKGS_REF" | \
                ${pkgs.jq}/bin/jq -r '.sha')"

    mkdir -p /tmp
    out=/tmp/insanepkgs/"$commit"
    dl=/tmp/insanepkgs-"$commit".tar.gz
    if [ ! -d "$out" ]; then
      rm -rf "$out"
      ${pkgs.curl}/bin/curl --fail -S -u "$GITHUB_USER":"$GITHUB_TOKEN" -L -o "$dl" \
          https://github.com/johnae/nixos-configuration/archive/"$commit".tar.gz
      mkdir -p "$out"
      cd "$out"
      tar zxf "$dl" --strip-components=1
    fi
    echo "$out"
  '';
in
pkgs.mkShell {
  buildInputs = [ fetch-insanepkgs ];
}
