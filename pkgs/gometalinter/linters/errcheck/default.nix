{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "errcheck-unstable-${version}";
  version = "2017-09-18";
  rev = "b1445a9dd8285a50c6d1661d16f0a9ceb08125f7";

  goPackagePath = "github.com/kisielk/errcheck";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/kisielk/errcheck";
    sha256 = "0xq4zwl201iw7hf2ln4yg20vpgz4gbghgx3f874kh8h9klk5rap7";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Checks for unchecked errors in go programs";
    homePage = "https://github.com/kisielk/errcheck";
  };
}
