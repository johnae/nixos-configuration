{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "deadcode-unstable-${version}";
  version = "2016-07-24";
  rev = "210d2dc333e90c7e3eedf4f2242507a8e83ed4ab";

  goPackagePath = "github.com/tsenart/deadcode";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/tsenart/deadcode";
    sha256 = "05kif593f4wygnrq2fdjhn7kkcpdmgjnykcila85d0gqlb1f36g0";
  };

  meta = {
    description = "Detect unused declarations in a Go package";
    homePage = "https://github.com/tsenart/deadcode";
  };
}
