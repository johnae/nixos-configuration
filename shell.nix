{pkgs ? import <nixpkgs> { }, ... }:

with pkgs;

let
  diskname = "testdisk.img";
  altdiskname = "testdiskalt.img";
  isoname = "result-iso";

  updateK3s = writeShellScriptBin "update-k3s" ''
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

  updateNixosChannels = writeShellScriptBin "update-nixos-channels" ''
    export PATH=${curl}/bin:${gnugrep}/bin:${gawk}/bin:$PATH
    curl -sS -I https://nixos.org/channels/nixos-unstable | grep Location: | awk '{printf "%s",$2}' | tr -d '\r\n' > nixos-channel
    nixpkgsUrl="$(cat nixos-channel)"/nixexprs.tar.xz
  '';

  bootVmFromIso = pkgs.writeShellScriptBin "boot-vm-from-iso" ''
    export PATH=${e2fsprogs}/bin:$PATH

    echo 'Removing ${diskname}, unless you ctrl-c now'
    read

    rm -f ${diskname}
    ${qemu}/bin/qemu-img create -f qcow2 ${diskname} 200G
    chattr +C ${diskname}

    rm -f ${altdiskname}
    ${qemu}/bin/qemu-img create -f qcow2 ${altdiskname} 20G
    chattr +C ${altdiskname}

    actualIsoPath="$(readlink ${isoname})"
    actualIso="$actualIsoPath"/iso/nixos-"$(echo "$actualIsoPath" | awk -F 'nixos-' '{print $2}')"

    qemu-system-x86_64 -enable-kvm -smp 2 -boot d -cdrom "$actualIso" -m 1024 -hda ${diskname} \
       -drive if=pflash,format=raw,readonly,file=${OVMF.fd}/FV/OVMF_CODE.fd \
       -drive if=pflash,format=raw,readonly,file=${OVMF.fd}/FV/OVMF_VARS.fd \
       -smbios type=2 \
       -net user,hostfwd=tcp::10022-:22 -net nic
  '';

  bootVm = pkgs.writeShellScriptBin "boot-vm" ''
    # -boot c 
    echo starting qemu
    qemu-system-x86_64 -enable-kvm -smp 2 -m 1024 -hda ${diskname} \
       -drive if=pflash,format=raw,readonly,file=${OVMF.fd}/FV/OVMF_CODE.fd \
       -drive if=pflash,format=raw,readonly,file=${OVMF.fd}/FV/OVMF_VARS.fd \
       -smbios type=2 \
       -net user,hostfwd=tcp::10022-:22 -net nic
  '';
in

  pkgs.mkShell {
    buildInputs = [ qemu bootVm bootVmFromIso sops updateK3s updateNixosChannels ];
    SOPS_PGP_FP = "06CAFD66CE7222C7FB0CA84314B5564DEB730BF5";
  }
