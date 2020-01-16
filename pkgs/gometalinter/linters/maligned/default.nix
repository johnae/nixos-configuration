{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "maligned-unstable-${version}";
  version = "2016-08-25";
  rev = "08c8e9db1bce03f1af283686c0943fcb75f0109e";

  goPackagePath = "github.com/mdempsky/maligned";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/mdempsky/maligned";
    sha256 = "03ywkmhrrlg0d7wa5hprvmfc55xn457pbnxj9570xpk9ivfjfai4";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Detect Go structs that would take less memory if their fields were sorted";
    homePage = "https://github.com/mdempsky/maligned";
  };
}
