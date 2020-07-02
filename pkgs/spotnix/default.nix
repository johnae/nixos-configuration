{ stdenv, rustPlatform, pkgconfig, openssl, sources }:

rustPlatform.buildRustPackage rec {
  pname = sources.spotnix.repo;
  version = sources.spotnix.rev;

  src = sources.spotnix;
  cargoSha256 = "0000000000000000000000000000000000000000000000000000";

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
