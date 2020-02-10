
{ stdenv, rustPlatform, fetchFromGitHub, pkgconfig, dbus, libpulseaudio, alsaLib, openssl }:

let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1rshicjyhnzbraxwdakpxv8f32xlzlnrvhx726p610whcra2cc76";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
     libpulseaudio
     openssl
     pkgconfig
     alsaLib
     dbus
  ];

    doCheck = false;
  #cargoBuildFlags = [ "--features pulseaudio_backend,dbus_mpris" ];
  cargoBuildFlags = [ "--features pulseaudio_backend" ];

  meta = with stdenv.lib; {
    description = "Simple spotify device daemon";
    homepage = https://github.com/spotifyd/spotifyd;
    license = licenses.gpl3;
    maintainers = [{
      email = "john@insane.se";
      github = "johnae";
      name = "John Axel Eriksson";
    }];
  };
}
