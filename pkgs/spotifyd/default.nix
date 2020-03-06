{ stdenv
, rustPlatform
, fetchFromGitHub
, pkgconfig
, dbus
, libpulseaudio
, alsaLib
, openssl
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "17a3a6r4gxa3v3a94177n7xf1kqvzhagid7mj7y5nr0yglhjv6v6";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ libpulseaudio openssl pkgconfig alsaLib dbus ];

  doCheck = false;
  #cargoBuildFlags = [ "--features pulseaudio_backend,dbus_mpris" ];
  cargoBuildFlags = [ "--features pulseaudio_backend" ];

  meta = with stdenv.lib; {
    description = "Simple spotify device daemon";
    homepage = "https://github.com/spotifyd/spotifyd";
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
