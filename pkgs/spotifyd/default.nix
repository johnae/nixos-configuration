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
  cargoSha256 = "0sc73cd2xdm4mffzx0hj0qcwlyln1ph1sacy89ffnaaaqjx7xpa0";

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
