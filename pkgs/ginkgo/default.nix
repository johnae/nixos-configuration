{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "ginkgo-unstable-${version}";
  version = "2018-06-30";
  rev = "e51bee6c2dd1df84f9cdde1e21f62f6d5a825a90";

  goPackagePath = "github.com/onsi/ginkgo";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/onsi/ginkgo";
    sha256 = "17aghw4vz38mpadb812zs1mh6vs9h0kh9nbf1cqygkdzqjda0v34";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Ginkgo the BDD testing framework";
    homePage = "https://github.com/onsi/ginkgo";
  };
}
