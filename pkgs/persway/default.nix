{ stdenv, lib, rustPlatform, sources }:

with rustPlatform;
buildRustPackage rec {
  pname = sources.persway.repo;
  version = sources.persway.rev;

  src = sources.persway;

  cargoSha256 = "0000000000000000000000000000000000000000000000000000";

  outputs = [ "out" ];

  meta = with stdenv.lib; {
    inherit (sources.persway) description homepage;
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
