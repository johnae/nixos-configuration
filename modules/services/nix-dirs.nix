{ config, lib, pkgs, ... }:

with lib;

## This just auto-creates /nix/var/nix/{profiles,gcroots}/per-user/<USER>
## for all extraUsers setup on the system. Without this home-manager refuses
## to run on boot when setup as a nix module and the user has yet to install
## anything through nix.

let

  cfg = config.services.nix-dirs;

in
{
  options.services.nix-dirs = {

    enable = mkEnableOption "ensures nix-dirs underneath /nix/var/nix/{profiles,gcroots} are created on boot. Home-manager really requires these to work";

  };

  config = mkIf cfg.enable {
    systemd.services.nix-dirs = {
      description = "Ensure nix dirs per-user are present";
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = ''
        ${lib.concatStringsSep "\n" (map (uname:
        ''
        mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/${uname}
        chown ${uname} /nix/var/nix/{profiles,gcroots}/per-user/${uname}

        ''
        ) (lib.attrNames config.users.extraUsers))}
      '';
      before = [ "nix-daemon.socket"];
      wantedBy = [ "nix-daemon.socket" ];
    };
  };

}