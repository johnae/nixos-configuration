{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "golint-unstable-${version}";
  version = "2018-04-28";
  rev = "470b6b0bb3005eda157f0275e2e4895055396a81";

  goPackagePath = "golang.org/x/lint";

  ## Because buildGoPackage doesn't ignore testdata
  preBuild = ''
    pushd "$NIX_BUILD_TOP/go/src/golang.org/x/lint" >/dev/null
    find -type d -name "testdata" | xargs -I{} rm -rf {}
    popd >/dev/null
  '';

  src = fetchgit {
    inherit rev;
    url = "https://github.com/golang/lint";
    sha256 = "0hq6kbsclb126wgx04kwalnn05i8i8lan2y3ibs31mrr5l9ag44n";
  };

  goDeps = ./deps.nix;

  meta = {
    description = "Go Lint";
    homePage = "https://github.com/golang/lint";
  };
}
