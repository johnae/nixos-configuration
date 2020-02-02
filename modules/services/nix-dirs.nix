{ config, lib, pkgs, ... }:

with lib;

## This just auto-creates /nix/var/nix/{profiles,gcroots}/per-user/<USER>
## for all extraUsers setup on the system. Without this home-manager refuses
## to run on boot when setup as a nix module and the user has yet to install
## anything through nix.

let

  cfg = config.services.nix-dirs;
  users = attrNames config.users.extraUsers;

in
{
  options.services.nix-dirs = {

    enable = mkEnableOption "ensures nix-dirs underneath /nix/var/nix/{profiles,gcroots} are created on boot. Home-manager really requires these to work";

  };

  config = mkIf cfg.enable {
    systemd.services.nix-dirs = rec {
      description = "Ensure nix dirs per-user are present";
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = ''
        ${concatStringsSep "\n" (map (uname:
        ''
        mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/${uname}
        chown ${uname} /nix/var/nix/{profiles,gcroots}/per-user/${uname}

        ''
        ) users)}
      '';
      before = map (uname: "home-manager-${uname}.service") users;
      wantedBy = before;
    };
  };

}