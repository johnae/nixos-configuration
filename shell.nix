let
  SOPS_PGP_FP = "782517BE26FBB0CC5DA3EFE59D91E5C4D9515D9E";

  nixpkgsPath = toString ./nix;
  pkgs = import nixpkgsPath { };

  #nixosChannelPath = toString ./nix/nixos-channel;
  nixosChannel = pkgs.sources.nixpkgs.url;

  ## enables reading from encrypted json within nix expressions
  nixSops = pkgs.writeStrictShellScriptBin "nix-sops" ''
    export SOPS_PGP_FP="${SOPS_PGP_FP}"
    OUTPUT="$(${pkgs.coreutils}/bin/mktemp /tmp/.sops.XXXXXXXXXX.json)"
    trap 'rm -f "$OUTPUT"' EXIT
    ${pkgs.sops}/bin/sops --output-type=json -d "$1" > "$OUTPUT"
    nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile \"$OUTPUT\")"
  '';

  nixFromYaml = pkgs.writeStrictShellScriptBin "nix-from-yaml" ''
    OUTPUT="$(${pkgs.coreutils}/bin/mktemp /tmp/.remarshal.XXXXXXXXXX.json)"
    trap 'rm -f "$OUTPUT"' EXIT
    ${pkgs.remarshal}/bin/remarshal -i "$1" -if yaml -of json > "$OUTPUT"
    nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile \"$OUTPUT\")"
  '';

  ## ditto - points to the above
  extraBuiltins = pkgs.writeText "extra-builtins.nix" ''
    { exec, ... }: {
      sops = path: exec [ ${nixSops}/bin/nix-sops path ];
      loadYAML = path: exec [ ${nixFromYaml}/bin/nix-from-yaml path ];
    }
  '';

  ## this will build an attribute such as a machine from default.nix
  ## or a package from the package collection - used by the update*system helpers
  ## below. We're enabling the extra-builtins here so that we can read from
  ## encrypted metadata (provided we have the keys ofc).
  build = pkgs.writeStrictShellScriptBin "build" ''
    unset NIX_PATH NIXPKGS_CONFIG
    NIX_PATH=nixpkgs="${nixpkgsPath}"
    export NIX_PATH
    export PATH=${pkgs.git}/bin:$PATH

    NIX_OUTLINK=''${NIX_OUTLINK:-}
    args=
    if [ -n "$NIX_OUTLINK" ]; then
        args="-o $NIX_OUTLINK"
    else
        args="--no-out-link"
    fi

    echo Building "$@" 1>&2
    ${pkgs.nix}/bin/nix-build $args --arg overlays [] --option extra-builtins-file ${extraBuiltins} "$@"
  '';

  ## this updates the local system, assuming the machine attribute to be the hostname
  updateSystem = pkgs.writeStrictShellScriptBin "update-system" ''
    profile=/nix/var/nix/profiles/system
    pathToConfig="$(${build}/bin/build -A machines."$(${pkgs.hostname}/bin/hostname)")"

    echo Ensuring nix-channel set in git repo is used
    sudo nix-channel --add "${nixosChannel}" nixos
    sudo nix-channel --update

    echo Updating system profile
    sudo nix-env -p "$profile" --set "$pathToConfig"

    echo Switching to new configuration
    if ! sudo "$pathToConfig"/bin/switch-to-configuration switch; then
            echo "warning: error(s) occurred while switching to the new configuration" >&2
            exit 1
    fi
  '';

  ## this updates a remote system over ssh
  updateRemoteSystem = pkgs.writeStrictShellScriptBin "update-remote-system" ''
    machine=''${1:-}
    reboot=''${2:-}
    after_update=

    if [ -n "$reboot" ]; then
        after_update="sudo shutdown -r now"
    fi

    profile=/nix/var/nix/profiles/system
    pathToConfig="$(${build}/bin/build -A machines."$machine")"

    export NIX_SSHOPTS="-T -o RemoteCommand=none"

    CHANNEL="${nixosChannel}"

    echo Copying closure to remote
    nix-copy-closure "$machine" "$pathToConfig"

    ## below requires sudo without password on remote, also requires an ssh config
    ## where the given machines are configured so they can be accessed via their
    ## names
    # shellcheck disable=SC2087
    ssh "$machine" -t -o RemoteCommand=none nix-shell -p bash --run bash <<SSH

    echo Ensuring nix-channel set in git repo is used
    sudo nix-channel --add '$CHANNEL' nixos && sudo nix-channel --update

    sudo nix-env -p '$profile' --set '$pathToConfig'
    echo Updating system profile

    echo Switching to new configuration
    if ! sudo '$pathToConfig'/bin/switch-to-configuration switch; then
        echo "warning: error(s) occurred while switching to the new configuration" >&2
        exit 1
    fi

    $after_update

    SSH
  '';

  diskname = "testdisk.img";
  altdiskname = "testdiskalt.img";
  isoname = "result-iso";

  updateK3s = pkgs.writeStrictShellScriptBin "update-k3s" ''
    export PATH=${latestRelease}/bin:${pkgs.niv}/bin:$PATH
    VERSION=''${1:-}
    if [ -z "$VERSION" ]; then
      VERSION="$(latest-release rancher/k3s)"
    fi
    niv update k3s -v "$VERSION"
  '';

  updateBuildkite = pkgs.writeStrictShellScriptBin "update-buildkite" ''
    export PATH=${latestRelease}/bin:${pkgs.niv}/bin:${pkgs.gnused}/bin:$PATH
    VERSION=''${1:-}
    if [ -z "$VERSION" ]; then
      VERSION="$(latest-release buildkite/agent | sed 's|^v||g')"
    fi
    niv update buildkite-darwin -v "$VERSION"
    niv update buildkite-linux -v "$VERSION"
  '';

  updateRustAnalyzer = pkgs.writeStrictShellScriptBin "update-rust-analyzer" ''
    export PATH=${latestRelease}/bin:${pkgs.niv}/bin:$PATH
    VERSION=''${1:-}
    if [ -z "$VERSION" ]; then
      VERSION="$(latest-release rust-analyzer/rust-analyzer)"
    fi
    niv update rust-analyzer -v "$VERSION"
  '';

  latestRelease = pkgs.writeStrictShellScriptBin "latest-release" ''
    export PATH=${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH
    REPO=''${1:-}
    curl -sS https://api.github.com/repos/"$REPO"/releases | \
             jq -r 'map(select(.tag_name | contains("rc") | not) | select(.tag_name != null)) | max_by(.tag_name | [splits("[-.a-zA-Z+]")] | map(select(length > 0)) | map(tonumber)) | .tag_name'
  '';

  updateNixosHardware = pkgs.writeStrictShellScriptBin "update-nixos-hardware" ''
    ${pkgs.nix-prefetch-github}/bin/nix-prefetch-github --rev master nixos nixos-hardware > nix/nixos-hardware.json
  '';

  updateRustPackageCargo = with pkgs;
    writeStrictShellScriptBin "update-rust-package-cargo" ''
      if [ -z "$1" ]; then
          echo "USAGE: $0 <attribute>"
          echo "EXAMPLE: $0 ripgrep"
          exit 1
      fi

      attr="$1"
      path="$(EDITOR="ls" nix edit -f . packages."$attr")"
      sed -i 's|cargoSha256.*|cargoSha256 = "0000000000000000000000000000000000000000000000000000";|' "$path"

      log="$(mktemp nix-rustbuild-log-"$attr".XXXXXXX)"
      trap 'rm -f $log' EXIT

      ${build}/bin/build -A packages."$attr" 2>&1 | tee "$log" || true
      cargoSha256="$(grep 'got:.*sha256:.*' "$log" | cut -d':' -f3-)"
      echo Setting cargoSha256 for "$attr" to "$cargoSha256"
      sed -i "s|cargoSha256.*|cargoSha256 = \"$cargoSha256\";|" "$path"
    '';

  updateFixedOutputDerivation = with pkgs;
    writeStrictShellScriptBin "update-fixed-output-derivation" ''
      if [ -z "$1" ]; then
          echo "USAGE: $0 <attribute>"
          echo "EXAMPLE: $0 argocd-ui"
          exit 1
      fi

      attr="$1"
      path="$(EDITOR="ls" nix edit -f . packages."$attr")"
      sed -i 's|outputHash =.*|outputHash = "0000000000000000000000000000000000000000000000000000";|' "$path"

      log="$(mktemp nix-fixed-output-drv-log-"$attr".XXXXXXX)"
      trap 'rm -f $log' EXIT

      ${build}/bin/build -A packages."$attr" 2>&1 | tee "$log" || true
      outputHash="$(grep 'got:.*sha256:.*' "$log" | cut -d':' -f3-)"
      echo Setting outputHash for "$attr" to "$outputHash"
      sed -i "s|outputHash =.*|outputHash = \"$outputHash\";|" "$path"
    '';

  updateNixpkgsDockerImage = pkgs.writeStrictShellScriptBin "update-nixpkgs-docker-image" ''
    ${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker nixpkgs/nix latest --quiet --json > containers/nixpkgs-image.json
  '';

  updateAll = pkgs.writeStrictShellScriptBin "update-all" ''
    ${updateNixosHardware}/bin/update-nixos-hardware
    ${updateRustAnalyzer}/bin/update-rust-analyzer
    ${updateK3s}/bin/update-k3s
    ${updateNixpkgsDockerImage}/bin/update-nixpkgs-docker-image
    ${updateBuildkite}/bin/update-buildkite
  '';

in
pkgs.mkShell {
  NIX_PATH = "nixpkgs=${nixpkgsPath}";
  buildInputs = with pkgs; [
    sops
    niv
    jq
    updateK3s
    updateNixosHardware
    updateAll
    updateRustAnalyzer
    updateRustPackageCargo
    updateFixedOutputDerivation
    build
    updateSystem
    updateRemoteSystem
    updateNixpkgsDockerImage
    updateBuildkite
    latestRelease
    insane-lib.strict-bash
  ];
  inherit SOPS_PGP_FP;
}
