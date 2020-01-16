{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "ineffassign-unstable-${version}";
  version = "2017-11-18";
  rev = "7bae11eba15a3285c75e388f77eb6357a2d73ee2";

  goPackagePath = "github.com/gordonklaus/ineffassign";

  ## Because buildGoPackage doesn't ignore testdata
  preBuild = ''
    pushd "$NIX_BUILD_TOP/go/src/github.com/gordonklaus/ineffassign" >/dev/null
    rm -rf testdata
    popd >/dev/null
  '';

  src = fetchgit {
    inherit rev;
    url = "https://github.com/gordonklaus/ineffassign";
    sha256 = "0g0s5478valb1zzz22dx7iply8jdmy47g9l7pjqw4kwyas6jlk2q";
  };

  meta = {
    description = "Detect ineffectual assignments in Go code";
    homePage = "https://github.com/gordonklaus/ineffassign";
  };
}
