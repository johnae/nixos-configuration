{stdenv, libdot, lib, writeText, settings, pkgs, ...}:

with lib;
with libdot;

let

  environment-import = {
    Unit = {
      Description = "Environment Import Target";
      Requires = [ "default.target" ];
      After = [ "default.target" ];
    };
  };

  services = (mapAttrs (name: value:
    let
      Requires = (value.Unit.Requires or []) ++ [ "environment-import.target" ];
      After = (value.Unit.After or []) ++ [ "environment-import.target" ];
      WantedBy = (value.Install.WantedBy or []) ++ [ "environment-import.target" ];
    in
      recursiveUpdate value {
        Unit = {
          inherit After Requires;
        };
        Install = {
          inherit WantedBy;
        };
      }
  ) settings.services);

  toSystemdIni = generators.toINI {
      mkKeyValue = key: value:
        let
          value' =
            if isBool value then (if value then "true" else "false")
            else toString value;
        in
          "${key}=${value'}";
    };

  create-unit = type: name: def:
  let
    unit = writeText "${name}.${type}" (toSystemdIni def);
  in
    ''
    ${libdot.copy { path = unit; to = ".config/systemd/user/${name}.${type}"; }}
    '';

  create-service = name: def: create-unit "service" name def;
  create-target = name: def: create-unit "target" name def;

in
  {
    __toString = self: ''
      echo "Ensuring .config/systemd/user directory..."
      ${libdot.mkdir { path = ".config/systemd/user"; }}
      ${concatStringsSep "\n" (mapAttrsToList create-target { inherit environment-import; } )}
      ${concatStringsSep "\n" (mapAttrsToList create-service services)}
    '';
  }
