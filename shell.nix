let
  pkgs-meta = with builtins; fromJSON ( readFile ./nixpkgs.json );
  pkgs = with builtins;
         import (fetchTarball { inherit (pkgs-meta) url sha256; }) {};

  diskname = "testdisk.img";
  altdiskname = "testdiskalt.img";
  isoname = "result-iso";

  updateK3s = pkgs.writeShellScriptBin "update-k3s" ''
    VERSION="$1"
    if [ -z "$VERSION" ]; then
      echo Please provide the version as argument
      exit 1
    fi
    URL="https://github.com/rancher/k3s/releases/download/$VERSION/k3s"

    HASH="$(nix-prefetch-url $URL 2>&1 | tail -1)"
    cat<<EOF>packages/k3s/metadata.json
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

  updateAll = pkgs.writeShellScriptBin "update-all" ''
    ${updateNixos}/bin/update-nixos
    ${updateNixosHardware}/bin/update-nixos-hardware
    ${updateHomeManager}/bin/update-home-manager
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
    buildInputs = with pkgs; [ qemu bootVm bootVmFromIso sops updateK3s
                               updateNixos updateHomeManager updateNixosHardware updateAll ];
    SOPS_PGP_FP = "782517BE26FBB0CC5DA3EFE59D91E5C4D9515D9E";
  }
