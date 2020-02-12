{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "gometalinter-v2-unstable-${version}";
  version = "2018-02-05";
  rev = "46cc1ea3778b247666c2949669a3333c532fa9c6";

  goPackagePath = "gopkg.in/alecthomas/gometalinter.v2";

  src = fetchgit {
    inherit rev;
    url = "https://gopkg.in/alecthomas/gometalinter.v2";
    sha256 = "0sfh8q8lssczg8s46k0n95ihrdpppmqgi66df6pn8wslz4s592rg";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Concurrently run Go lint tools and normalise their output";
    homePage = "https://github.com/alecthomas/gometalinter";
  };

  postInstall = ''
    ln -sf $bin/bin/gometalinter.v2 $bin/bin/gometalinter
  '';
}
