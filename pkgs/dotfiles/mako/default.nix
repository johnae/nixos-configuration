{stdenv, libdot, writeText, settings, ...}:

let

  toConfig = libdot.setToStringSep "\n";
  config = writeText "config" ''
  ${toConfig settings.mako-config (name: value: "${name}=${value}")}
  '';

in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/mako"; }}
      ${libdot.copy { path = config; to = ".config/mako/config";  }}
    '';
  }