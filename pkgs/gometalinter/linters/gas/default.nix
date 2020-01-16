{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "gas-unstable-${version}";
  version = "2018-02-02";
  rev = "8b87505d975585b41ba12f597b4b639a86c4d2b1";

  goPackagePath = "github.com/GoASTScanner/gas";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/GoASTScanner/gas";
    sha256 = "06x90ny8m03jlfd7h62c8jqiv1i5pvvjzy6qswwy0rkl8hm7gbyh";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Go AST Scanner";
    homePage = "https://github.com/GoASTScanner/gas";
  };
}
