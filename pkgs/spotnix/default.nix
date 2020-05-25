{ stdenv, rustPlatform, pkgconfig, openssl, sources }:

rustPlatform.buildRustPackage rec {
  pname = sources.spotnix.repo;
  version = sources.spotnix.rev;

  src = sources.spotnix;
  cargoSha256 = "0p0jvd2f0x5hx1lzk83x00ayvg7ac127cdxnv7mzhr9qpvk6059s";

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
