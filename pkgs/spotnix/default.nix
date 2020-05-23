{ stdenv, rustPlatform, pkgconfig, openssl, sources }:

rustPlatform.buildRustPackage rec {
  pname = sources.spotnix.repo;
  version = sources.spotnix.rev;

  src = sources.spotnix;
  cargoSha256 = "0103f0fz66flqn29wjiay6lgq46m4vc6lz4sv4igr2xh99ki5rk0";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ openssl ];

  doCheck = false;

  meta = with stdenv.lib; {
    inherit (sources.spotnix) description homepage;
    license = licenses.mit;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
