{ config, lib, pkgs, ... }:
let
  wiped = [ "@" "@var" ]; ## @ == /
  kept = [
    "/var/lib/bluetooth"
    "/var/lib/iwd"
    "/var/lib/wireguard"
  ];
in
{

  ## wipe all state by default on boot for a squeaky clean machine
  ## this is in a ramfs so no need to clean up really
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    echo Wiping ephemeral data
    mkdir -p /mnt
    mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/disk/by-label/root /mnt
    ${lib.concatStringsSep "\n" (
      map (vol: ''
          for vol in $(find "/mnt/${vol}" -depth -inum 256)
          do
            echo Deleting subvolume "$vol"
            btrfs sub delete "$vol"
          done
          echo Creating subvolume "$vol" from /mnt/@blank snapshot
          btrfs sub snapshot /mnt/@blank /mnt/${vol}
        ''
        ) wiped
    )}
    ${lib.concatStringsSep "\n" (
      map (m:
          let
              dir = builtins.dirOf m;
            in
              ''
                if [ ! -e "/mnt/@keep${m}" ]; then
                  echo Creating subvolume "/keep${m}"
                  mkdir -p "/mnt/@keep${dir}"
                  btrfs sub create "/mnt/@keep${m}"
                fi
              ''
        ) kept
    )}
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
