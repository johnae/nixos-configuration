{ config, lib, pkgs, ... }:
## This requires certain things from your drive partitioning
## see ../installer/install.sh
let
  cfg = config.boot.btrfsCleanBoot;
in
with lib; {

  options.boot.btrfsCleanBoot = {
    enable = mkEnableOption
      "enable the cleanboot option to erase your / and /var etc on every boot";

    wipe = mkOption {
      type = types.listOf types.str;
      example = [ "@" "@var" ];
      description = ''
        Btrfs subvolumes to wipe on boot
      '';
    };

    keep = mkOption {
      type = types.listOf types.str;
      example = [ "/var/lib/bluetooh" "/var/lib/iwd" "/var/lib/docker" ];
      description = ''
        Paths to keep from being wiped on boot
      '';
    };

  };

  config = mkIf cfg.enable {

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
          ) cfg.wipe
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
          ) cfg.keep
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
      ) cfg.keep;
  };

}
