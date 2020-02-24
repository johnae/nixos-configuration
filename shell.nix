let
  pkgs-meta = with builtins; fromJSON (readFile ./nixpkgs.json);
  pkgs = with builtins;
    import (fetchTarball { inherit (pkgs-meta) url sha256; }) {};

  diskname = "testdisk.img";
  altdiskname = "testdiskalt.img";
  isoname = "result-iso";

  updateK3s = pkgs.writeShellScriptBin "update-k3s" ''
    export PATH=${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH
    VERSION="$1"
    if [ -z "$VERSION" ]; then
      VERSION="$(curl https://api.github.com/repos/rancher/k3s/releases | jq -r '[.[] | select(.prerelease == false)]' | jq -r '. | first.tag_name')"
    fi
    URL="https://github.com/rancher/k3s/releases/download/$VERSION/k3s"
    HASH="$(nix-prefetch-url "$URL" 2>&1 | tail -1)"
    cat<<EOF>pkgs/k3s/metadata.json
    {
      "hash": "sha256:$HASH",
      "url": "$URL",
      "version": "$VERSION"
    }
    EOF
  '';

  updateRustAnalyzer = pkgs.writeShellScriptBin "update-rust-analyzer" ''
    export PATH=${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH
    VERSION="$1"
    if [ -z "$VERSION" ]; then
      VERSION="$(curl https://api.github.com/repos/rust-analyzer/rust-analyzer/releases | jq -r first.tag_name)"
    fi
    URL="https://github.com/rust-analyzer/rust-analyzer/releases/download/$VERSION/ra_lsp_server-linux"
    HASH="$(nix-prefetch-url "$URL" 2>&1 | tail -1)"
    cat<<EOF>pkgs/rust-analyzer-bin/metadata.json
    {
      "hash": "sha256:$HASH",
      "url": "$URL",
      "version": "$VERSION"
    }
    EOF
  '';

  updateNixos = pkgs.writeShellScriptBin "update-nixos" ''
    export PATH=${pkgs.curl}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:$PATH
    curl -sS -I https://nixos.org/channels/nixos-unstable | grep Location: | awk '{printf "%s",$2}' | tr -d '\r\n' > nixos-channel
    nixpkgsUrl="$(cat nixos-channel)"/nixexprs.tar.xz
    hash="$(nix-prefetch-url --type sha256 --unpack "$nixpkgsUrl")"
    cat<<EOF>nixpkgs.json
    {
      "url": "$nixpkgsUrl",
      "sha256": "$hash"
    }
    EOF
  '';

  updateHomeManager = pkgs.writeShellScriptBin "update-home-manager" ''
    ${pkgs.nix-prefetch-github}/bin/nix-prefetch-github --rev master rycee home-manager > modules/home-manager.json
  '';

  updateNixosHardware = pkgs.writeShellScriptBin "update-nixos-hardware" ''
    ${pkgs.nix-prefetch-github}/bin/nix-prefetch-github --rev master nixos nixos-hardware > nixos-hardware.json
  '';

  updateUserNixpkg = with pkgs;
    writeShellScriptBin "update-user-nixpkg" ''
      metadata=''${1:-} ## the metadata.json file
      if [ -z "$metadata" ]; then
        echo "Please give me the metadata.json"
        exit 1
      fi
      dir="$(dirname "$metadata")"

      RED='\033[0;31m'
      GREEN='\033[0;32m'
      NEUTRAL='\033[0m'
      BOLD='\033[1m'

      neutral() { printf "%b" "$NEUTRAL"; }
      start() { printf "%b" "$1"; }
      clr() { start "$1""$2"; neutral; }
      max_retries=2
      retries=$max_retries

      rm -f "$dir"/metadata.tmp.json

      if ${jq}/bin/jq -e ".owner == null or .repo == null" < "$metadata" >/dev/null; then
        clr "$NEUTRAL" "skipping "$(basename "$dir")" - metadata not supported\n"
        exit 0
      fi

      # shellcheck disable=SC2046
      set $(${jq}/bin/jq -r '.owner + " " + .repo' < "$metadata")
      ## above sets $1 and $2

      while true; do
        clr "$NEUTRAL" "Prefetching $1/$2 master branch...\n"
        set +e
        if ! ${nix-prefetch-github}/bin/nix-prefetch-github --rev master "$1" "$2" > "$dir"/metadata.tmp.json; then
          clr "$RED" "ERROR: prefetch of $1/$2 failed\n"
          retries=$((retries - 1))
          clr "$GREEN" "   $1/$2 - retry $((max_retries - retries)) of $max_retries\n"
          if [[ "$retries" -ne "0" ]]; then
            continue
          else
            clr "$RED" "FAIL: $1/$2 failed prefetch even after retrying\n"
            exit 1
          fi
        fi
        set -e
        clr "$BOLD" "Completed prefetching $1/$2...\n"

        if [ ! -s "$dir"/metadata.tmp.json ]; then
            clr "$RED" "ERROR: $dir/metadata.tmp.json is empty\n"
            if [[ "$retries" -ne "0" ]]; then
              retries=$((retries - 1))
              clr "$GREEN" "   $1/$2 - retry $((max_retries - retries)) of $max_retries\n"
              continue
            else
              clr "$RED" "FAIL: $dir/metadata.tmp.json is empty even after retrying\n"
              exit 1
            fi
            exit 1
        fi
        break
      done

      if ! ${jq}/bin/jq < "$dir"/metadata.tmp.json > /dev/null; then
          clr "$RED" "ERROR: $dir/metadata.tmp.json is not valid json\n"
          cat "$dir"/metadata.tmp.json
          exit 1
      fi

    '';

  updateUserNixpkgs = with pkgs;
    writeShellScriptBin "update-user-nixpkgs" ''

      #RED='\033[0;31m'
      GREEN='\033[0;32m'
      NEUTRAL='\033[0m'
      BOLD='\033[1m'

      neutral() { printf "%b" "$NEUTRAL"; }
      start() { printf "%b" "$1"; }
      clr() { start "$1""$2"; neutral; }

      echo Updating metadata.json files in pkgs...

      ${findutils}/bin/find pkgs/ -type f -name metadata.json | \
        ${findutils}/bin/xargs -I{} -n1 -P3 ${updateUserNixpkg}/bin/update-user-nixpkg {}

      pkgs_updated=0
      for pkg in pkgs/*; do
          if [ -d "$pkg" ] && [ -e "$pkg"/metadata.tmp.json ]; then
             if ! ${diffutils}/bin/diff "$pkg"/metadata.json "$pkg"/metadata.tmp.json > /dev/null; then
               pkgs_updated=$((pkgs_updated + 1))
               clr "$BOLD" "Package $(basename "$pkg") was updated\n"
               mv "$pkg"/metadata.tmp.json "$pkg"/metadata.json
             fi
             rm -f "$pkg"/metadata.tmp.json
          fi
      done

      if [ "$pkgs_updated" -gt 0 ]; then
        clr "$BOLD" "$pkgs_updated packages were updated\n"
      else
        clr "$GREEN" "No package metadata was updated\n"
      fi
    '';

  updateAll = pkgs.writeShellScriptBin "update-all" ''
    ${updateNixos}/bin/update-nixos
    ${updateNixosHardware}/bin/update-nixos-hardware
    ${updateHomeManager}/bin/update-home-manager
    ${updateRustAnalyzer}/bin/update-rust-analyzer
    ${updateK3s}/bin/update-k3s
    ${updateUserNixpkgs}/bin/update-user-nixpkgs
  '';

  bootVmFromIso = pkgs.writeShellScriptBin "boot-vm-from-iso" ''
    export PATH=${pkgs.e2fsprogs}/bin:$PATH

    echo 'Removing ${diskname}, unless you ctrl-c now'
    read

    rm -f ${diskname}
    ${pkgs.qemu}/bin/qemu-img create -f qcow2 ${diskname} 200G
    chattr +C ${diskname}

    rm -f ${altdiskname}
    ${pkgs.qemu}/bin/qemu-img create -f qcow2 ${altdiskname} 20G
    chattr +C ${altdiskname}

    actualIsoPath="$(readlink ${isoname})"
    actualIso="$actualIsoPath"/iso/nixos-"$(echo "$actualIsoPath" | awk -F 'nixos-' '{print $2}')"

    qemu-system-x86_64 -enable-kvm -smp 2 -boot d -cdrom "$actualIso" -m 1024 -hda ${diskname} \
       -drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
       -drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd \
       -smbios type=2 \
       -net user,hostfwd=tcp::10022-:22 -net nic
  '';

  bootVm = pkgs.writeShellScriptBin "boot-vm" ''
    # -boot c
    echo starting qemu
    qemu-system-x86_64 -enable-kvm -smp 2 -m 1024 -hda ${diskname} \
       -drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
       -drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF_VARS.fd \
       -smbios type=2 \
       -net user,hostfwd=tcp::10022-:22 -net nic
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    qemu
    bootVm
    bootVmFromIso
    sops
    updateK3s
    updateNixos
    updateHomeManager
    updateNixosHardware
    updateAll
    updateUserNixpkg
    updateUserNixpkgs
    updateRustAnalyzer
  ];
  SOPS_PGP_FP = "782517BE26FBB0CC5DA3EFE59D91E5C4D9515D9E";
}
