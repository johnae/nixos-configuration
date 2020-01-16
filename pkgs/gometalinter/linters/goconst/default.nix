{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "goconst-unstable-${version}";
  version = "2017-07-03";
  rev = "9740945f5dcb78c2faa8eedcce78c2a04aa6e1e9";

  goPackagePath = "github.com/jgautheron/goconst";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/jgautheron/goconst";
    sha256 = "0zhscvv9w54q1h2vs8xx3qkz98cf36qhxjvdq0xyz3qvn4vhnyw6";
  };

  meta = {
    description = "Find in Go repeated strings that could be replaced by a constant";
    homePage = "https://github.com/jgautheron/goconst";
  };
}
