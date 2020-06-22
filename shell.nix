let
  SOPS_PGP_FP = "782517BE26FBB0CC5DA3EFE59D91E5C4D9515D9E";

  nixpkgsPath = toString ./nix;
  pkgs = import nixpkgsPath { };
  metadata = toString ./metadata;

  nixosChannel = pkgs.sources.nixpkgs.url;

  nix = pkgs.nix;
  nix-plugins = pkgs.nix-plugins;

  NIX_CONF_DIR =
    let
      nixConf = pkgs.writeTextDir "opt/nix.conf" ''
        # experimental-features = nix-command flakes ca-references
        extra-builtins-file = ${extraBuiltins}
        plugin-files = ${nix-plugins}/lib/nix/plugins/libnix-extra-builtins.so
      '';
    in
    "${nixConf}/opt";

  ## enables reading from encrypted json within nix expressions
  nixSops = pkgs.writeStrictShellScriptBin "nix-sops" ''
    export SOPS_PGP_FP="${SOPS_PGP_FP}"
    OUTPUT="$(${pkgs.coreutils}/bin/mktemp /tmp/.sops.XXXXXXXXXX.json)"
    trap 'rm -f "$OUTPUT"' EXIT
    ${pkgs.sops}/bin/sops --output-type=json -d "$1" > "$OUTPUT"
    nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile \"$OUTPUT\")"
  '';

  ## allows decrypting a file to an output path for reading into a nix expression
  nixSopsPath = pkgs.writeStrictShellScriptBin "nix-sops-path" ''
    export SOPS_PGP_FP="${SOPS_PGP_FP}"
    OUTPUT="$(${pkgs.coreutils}/bin/mktemp /tmp/sops.XXXXXXXXXX)"
    ${pkgs.sops}/bin/sops -d "$1" > "$OUTPUT"
    nix-instantiate --eval -E "$OUTPUT"
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
      sopsPath = path: exec [ ${nixSopsPath}/bin/nix-sops-path path ];
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
    NIXPKGS_ALLOW_UNFREE=1
    export NIX_PATH NIXPKGS_ALLOW_UNFREE
    export PATH=${pkgs.git}/bin:$PATH
    export NIX_CONF_DIR=${NIX_CONF_DIR}

    NIX_OUTLINK=''${NIX_OUTLINK:-}
    args=
    if [ -n "$NIX_OUTLINK" ]; then
        args="-o $NIX_OUTLINK"
    else
        args="--no-out-link"
    fi

    echo Building "$@" 1>&2
    ${nix}/bin/nix-build $args --arg overlays [] "$@"
  '';

  ## this updates the local system, assuming the machine attribute to be the hostname
  updateSystem = pkgs.writeStrictShellScriptBin "update-system" ''
    export NIX_CONF_DIR=${NIX_CONF_DIR}
    machine="$(${pkgs.hostname}/bin/hostname)"

    profile=/nix/var/nix/profiles/system
    pathToConfig="$(${build}/bin/build -A machines."$machine")"

    echo Ensuring nix-channel set in git repo is used
    sudo -E nix-channel --add "${nixosChannel}" nixos
    sudo -E nix-channel --update

    if [ -d "${metadata}/$machine/root" ]; then
      roottmp="$(mktemp -d /tmp/roottmp.XXXXXXXX)"
      trap 'sudo rm -rf "$roottmp"' EXIT
      cp -a ${metadata}/"$machine"/root/* "$roottmp"/
      for file in $(${pkgs.fd}/bin/fd . --type f "$roottmp"); do
        echo Decrypting "$file"
        ${pkgs.sops}/bin/sops -d -i "$file"
      done
      sudo chown -R root:root "$roottmp"/*
      sudo cp -a "$roottmp"/* /
      sudo rm -rf "$roottmp"
    fi

    echo Updating system profile
    sudo -E nix-env -p "$profile" --set "$pathToConfig"

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

    if [ -d "${metadata}/$machine/root" ]; then
      roottmp="$(mktemp -d /tmp/roottmp.XXXXXXXX)"
      trap 'sudo rm -rf "$roottmp"' EXIT
      cp -a ${metadata}/"$machine"/root/* "$roottmp"/
      for file in $(${pkgs.fd}/bin/fd . --type f "$roottmp"); do
        echo Decrypting "$file"
        ${pkgs.sops}/bin/sops -d -i "$file"
      done
      scp -r "$roottmp" "$machine:roottmp"
    fi

    ## below requires sudo without password on remote, also requires an ssh config
    ## where the given machines are configured so they can be accessed via their
    ## names
    # shellcheck disable=SC2087
    ssh "$machine" -t -o RemoteCommand=none nix-shell -p bash --run bash <<SSH

    if [ -d roottmp ]; then
      sudo chown -R root:root roottmp/*
      sudo cp -a roottmp/* /
      sudo rm -rf roottmp
    fi

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

  ## This bootstraps and installs a remote system over ssh, the requirement would
  ## be that the remote system is booted via pxe or from ISO with a working ssh
  ## server. We're not managing all dependencies through Nix here, at least not yet.
  ## So we assume there's sufficient tooling basically until we hit the install script.
  installRemoteSystem = pkgs.writeStrictShellScriptBin "install-remote-system" ''
    ## This script can be used when pxe booting a machine into some
    ## distro from where you can do an install.

    installscript=${./. + "/installer/install.sh"}

    address=''${1:-}
    machine=''${2:-}

    SKIP_INSTALL=''${SKIP_INSTALL:-}
    DISK_PASSWORD=''${DISK_PASSWORD:-}
    ADDITIONAL_VOLUMES=''${ADDITIONAL_VOLUMES:-}

    export NIX_SSHOPTS="-T -o RemoteCommand=none"

    ## Bootstrap start - this will prep remote system with some
    ## encrypted ram disk volumes used during install for security.
    ssh "$address" -t -o RemoteCommand=none bash <<'SSH'
    set -euo pipefail
    set -x

    ## We don't really care about this, only used during install
    tmpdiskpass="$(openssl rand -hex 32)"

    ## We want swap to be disabled so that any tmpfs doesn't run the
    ## risk of being swapped to disk.
    if [ "$(swapon -s | wc -l)" != "0" ]; then
        echo "Swap is turned on, please disable it during install"
        exit 1
    fi

    echo Preparing machine for installation

    mkdir -p /ramdisk

    ## Use a ramdisk for this for security
    mount -t tmpfs -o size=32g tmpfs /ramdisk

    ## Writing random bytes would be better but
    ## it's just too slow - even with /dev/urandom.
    ## Since it's all in RAM anyway I believe this
    ## should be secure enough, especially given
    ## the encryption.
    fallocate -l 32G /ramdisk/installdata.img

    echo "$tmpdiskpass" | cryptsetup luksFormat /ramdisk/installdata.img -d -
    echo "$tmpdiskpass" | cryptsetup open /ramdisk/installdata.img installdata -d -
    mkfs.btrfs /dev/mapper/installdata

    mkdir -p /srv
    mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/mapper/installdata /srv
    btrfs subvolume create /srv/@etcnix
    btrfs subvolume create /srv/@secrets
    btrfs subvolume create /srv/@nix
    umount /srv

    mkdir -p /etc/nix /secrets
    mkdir -p -m 0755 /nix

    mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@nix /dev/mapper/installdata /nix
    mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@etcnix /dev/mapper/installdata /etc/nix
    mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@secrets /dev/mapper/installdata /secrets
    chown root /nix

    echo "build-users-group =" > /etc/nix/nix.conf
    curl https://nixos.org/nix/install | sh
    . $HOME/.nix-profile/etc/profile.d/nix.sh

    nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
    nix-channel --update

    nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

    echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' >> $HOME/.bashrc

    SSH
    ## Bootstrap end

    ## Now build the system locally
    pathToConfig="$(build -A machines."$machine")"

    ## Transfer the closure to the remote (encrypted) nix store
    nix-copy-closure "$address" "$pathToConfig"

    ## Transfer the install script
    scp "$installscript" "$address":install.sh

    ## Start install process
    # shellcheck disable=SC2087
    ssh "$address" -t -o RemoteCommand=none bash <<SSH
    set -euo pipefail
    set -x

    chmod +x ./install.sh
    ## The install.sh expects this file to contain the path to the closure
    echo "$pathToConfig" > /etc/system-closure-path

    ## Run the install propagating a few variables that may have been given
    ## locally.
    SKIP_INSTALL="$SKIP_INSTALL" DISK_PASSWORD="$DISK_PASSWORD" ADDITIONAL_VOLUMES="$ADDITIONAL_VOLUMES" ./install.sh

    reboot

    SSH
  '';

  updateProgramsSqlite = pkgs.writeStrictShellScriptBin "update-programs-sqlite" ''
    export PATH=${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.xz}:$PATH
    dir="$(pwd)"
    cd /tmp
    curl -o nixexprs.tar.xz -L -sS https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz
    tar xJf nixexprs.tar.xz
    cp nixos-*/programs.sqlite "$dir"/
    rm -rf nixos-* nixexprs.tar.xz
  '';

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
    installRemoteSystem
    updateNixpkgsDockerImage
    updateBuildkite
    updateProgramsSqlite
    latestRelease
    insane-lib.strict-bash
  ];
  inherit SOPS_PGP_FP;
}
