{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.mako;

  configFile = conf:
    pkgs.writeText "config" ''
      ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}") conf)}
    '';
in
{
  options.programs.mako = {
    enable = mkEnableOption "Wayland notification dbus daemon.";
    settings = mkOption {
      description = "Config attributes";
      type = types.attrs;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.mako ];
    xdg.configFile."mako/config".source = configFile cfg.settings;
  };
}
