{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.nixpkgs-fmt.repo;
  version = sources.nixpkgs-fmt.rev;

  src = sources.nixpkgs-fmt;
  cargoSha256 = "0lp0mhcrg2gkj5i4vd915k16rhqaqwpw8r7f2prjay6sjv204gq2";

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
