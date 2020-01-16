{stdenv, libdot, writeText, ...}:

let
  config = writeText "user-pulse-config" ''
    .include /etc/pulse/default.pa
    # automatically switch to newly-connected devices
    load-module module-switch-on-connect
  '';
in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/pulse"; }}
      ${libdot.copy { path = config; to = ".config/pulse/default.pa"; }}
    '';
  }