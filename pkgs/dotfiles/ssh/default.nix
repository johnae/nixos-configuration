{stdenv, lib, libdot, writeText, writeScriptBin, pkgs, settings, ...}:

with settings.ssh;
with lib;
with libdot;

let

  toHost = h: concatStringsSep "\n" (mapAttrsToList
         (name: value: ''${"  "}${name} ${value}'') h);

  toHosts = hs: concatStringsSep "\n" (mapAttrsToList
          (name: value: ''
          Host ${name}
          ${toHost value}
          '') hs);

  config = writeText "ssh-config" (toHosts hosts);

in

  {
    __toString = self: ''
      ${mkdir { path = ".ssh"; mode = "0700"; }}
      ${copy { path = config; to = ".ssh/config"; mode = "0600"; }}
    '';
  }