{ stdenv, rustPlatform, fetchFromGitHub, pkgconfig, openssl }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "0103f0fz66flqn29wjiay6lgq46m4vc6lz4sv4igr2xh99ki5rk0";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ openssl ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Spotify for UNIX";
    homepage = "https://github.com/johnae/spotnix";
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
