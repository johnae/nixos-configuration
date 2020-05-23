{ stdenv, lib, rustPlatform, sources }:

with rustPlatform;
buildRustPackage rec {
  pname = sources.persway.repo;
  version = sources.persway.rev;

  src = sources.persway;

  cargoSha256 = "0pqhqsiv1n9kw5xq9pyrkcr2yd6vdhy64r2az46imymds7phs2wq";

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
