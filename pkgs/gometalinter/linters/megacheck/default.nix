{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "tools-unstable-${version}";
  version = "2018-01-10";
  rev = "8ed405e85c65fb38745a8eafe01ee9590523f172";

  goPackagePath = "honnef.co/go/tools";

  ## Because buildGoPackage doesn't ignore testdata
  preBuild = ''
    pushd "$NIX_BUILD_TOP/go/src/honnef.co/go/tools" >/dev/null
    find -type d -name "testdata" | xargs -I{} rm -rf {}
    popd >/dev/null
  '';

  src = fetchgit {
    inherit rev;
    url = "https://github.com/dominikh/go-tools";
    sha256 = "04hxmbjlq1hmjr31m0zks3sqwibrdfpx1pna0scnxj8hv3yb9zjy";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Runs staticcheck, gosimple and unused at once";
    homePage = "https://github.com/dominikh/go-tools";
  };
}
