{ stdenv, lib, rustPlatform, sources }:

with rustPlatform;
buildRustPackage rec {
  pname = sources.persway.repo;
  version = sources.persway.rev;

  src = sources.persway;

  cargoSha256 = "0554k3wz8a0a21n2890dg3f7zndipx7dabqnxfml3kgbn8v5n87q";

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
