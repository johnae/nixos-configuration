{stdenv, libdot, lib, writeText, settings, pkgs, ...}:

with lib;
with libdot;

let
  toStarshipINI = generators.toINI {
      mkKeyValue = key: value:
        let
          value' =
            if isBool value then (if value then "true" else "false")
            else ''"${toString value}"'';
        in
          "${key}=${value'}";
    };
  config = writeText "starship.toml" (toStarshipINI settings.starship);
in
  {
    __toString = self: ''
      ${copy { path = config; to = ".config/starship.toml";}}
    '';
  }
