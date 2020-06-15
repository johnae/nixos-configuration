{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.nixpkgs-fmt.repo;
  version = sources.nixpkgs-fmt.rev;

  src = sources.nixpkgs-fmt;
  cargoSha256 = "0p86gq1kmngy9yr7hpqd0vhjv2s7jl81vacffz8si5w8i79zrzy5";

  doCheck = false;

  meta = with stdenv.lib; {
    inherit (sources.nixpkgs-fmt) description homepage;
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
