{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "unconvert-unstable-${version}";
  version = "2016-08-03";
  rev = "beb68d938016d2dec1d1b078054f4d3db25f97be";

  goPackagePath = "github.com/mdempsky/unconvert";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/mdempsky/unconvert";
    sha256 = "13jg2zqa508vdl593bf4an64lhwmkrjd3kvnk64g7aqg3nixbis5";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Remove unnecessary type conversions from Go source";
    homePage = "https://github.com/mdempsky/unconvert";
  };
}
