{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.nixpkgs-fmt.repo;
  version = sources.nixpkgs-fmt.rev;

  src = sources.nixpkgs-fmt;
  cargoSha256 = "1fiwvnphmy5hkqipyd6ng45hg0652nbra6iy5yh2ps9jy950n057";

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
