{ config, lib, pkgs, ... }:
let
  ephemeral = [ "@" "@var" ];
  mountpoints = [ "boot" "home" "var" "nix" "keep" ];
  kept = [ "/var/lib/bluetooth" "/var/lib/iwd" ];
in
{

  ## wipe all state by default on boot for a squeaky clean machine
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    echo Wiping all state
    mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/disk/by-label/root /mnt
    ${lib.concatStringsSep "\n" (
      map (vol: ''
          for vol in $(find "/mnt/${vol}" -depth -inum 256)
          do
            btrfs sub delete "$vol"
          done
          btrfs sub create /mnt/${vol}
        ''
        ) ephemeral
    )}
    mkdir -p "${lib.concatStringsSep " " (map (m: ''"/mnt/@/${m}"'') mountpoints)}"
    mkdir -p "${lib.concatStringsSep " " (map (m: ''"/mnt/@keep${m}"'') kept)}"
    umount /mnt
  '';

  systemd.mounts = map
    (where:
      {
        before = [ "local-fs.target" ];
        wantedBy = [ "local-fs.target" ];
        what = "/keep${where}";
        inherit where;
        type = "none";
        options = "bind";
      }
    ) kept;

}
