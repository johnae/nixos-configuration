{ stdenv, lib, rustPlatform, sources }:

with rustPlatform;
buildRustPackage rec {
  pname = sources.persway.repo;
  version = sources.persway.rev;

  src = sources.persway;

  cargoSha256 = "03p9gl9l4p6cj7jggdiiv00pfpmm88zwj2vc39a6ccrv46hqq5qf";

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
