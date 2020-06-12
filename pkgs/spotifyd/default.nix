{ stdenv
, rustPlatform
, pkgconfig
, dbus
, libpulseaudio
, alsaLib
, openssl
, sources
}:

rustPlatform.buildRustPackage rec {
  pname = sources.spotifyd.repo;
  version = sources.spotifyd.rev;

  src = sources.spotifyd;
  cargoSha256 = "04xxzy5fjwgqvr3jwn86jv4ambshm828w8m494p265wlqi6fkzv1";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ libpulseaudio openssl pkgconfig alsaLib dbus ];

  doCheck = false;
  #cargoBuildFlags = [ "--features pulseaudio_backend,dbus_mpris" ];
  cargoBuildFlags = [ "--features pulseaudio_backend" ];

  meta = with stdenv.lib; {
    inherit (sources.spotifyd) description homepage;
    license = licenses.gpl3;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
