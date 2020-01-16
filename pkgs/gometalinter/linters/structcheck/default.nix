{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "check-unstable-${version}";
  version = "2018-01-21";
  rev = "86da7ade2cccfc1c5d6beeb55e5c65eba54f5f3c";

  goPackagePath = "github.com/opennota/check";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/opennota/check";
    sha256 = "1crlabac5ph2z3gxa50z1x2k5q3cfp5qplbyaxz7r1rynkvsji0h";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Find unused struct fields in Go code";
    homePage = "https://github.com/opennota/check";
  };
}
