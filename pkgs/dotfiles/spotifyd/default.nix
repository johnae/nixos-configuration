{
  stdenv,
  lib,
  libdot,
  writeText,
  settings,
  ...
}:


let
  config = settings.spotifyd;
  spotifydconf = writeText "spotifyd.conf" ''
  [global]
  username = ${config.username}
  password_cmd = ${config.password_cmd}
  backend = ${config.backend}
  mixer = ${config.mixer}
  volume-control = ${config.volume-control}
  # onevent = command_to_run_on_playback_events
  device_name = ${config.device_name}
  bitrate = ${toString config.bitrate}
  cache_path = ${config.cache_path}
  volume-normalisation = ${if config.volume-normalisation then "true" else "false"}
  normalisation-pregain = ${config.normalisation-pregain}
  '';

in

  {
    dirmode = "0700";
    filemode = "0600";
    __toString = self: ''
      ${libdot.mkdir { path = ".config/spotifyd"; mode = self.dirmode; }}
      ${libdot.copy { path = spotifydconf; to = ".config/spotifyd/spotifyd.conf"; mode = self.filemode; }}
      '';
  }
