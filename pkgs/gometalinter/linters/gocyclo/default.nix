{ stdenv, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn }:

buildGoPackage rec {
  name = "gocyclo-unstable-${version}";
  version = "2015-02-09";
  rev = "aa8f8b160214d8dfccfe3e17e578dd0fcc6fede7";

  goPackagePath = "github.com/alecthomas/gocyclo";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/alecthomas/gocyclo";
    sha256 = "094rj97q38j53lmn2scshrg8kws8c542yq5apih1ahm9wdkv8pxr";
  };

  meta = {
    description =
      "Calculate cyclomatic complexities of functions in Go source code";
    homePage = "https://github.com/alecthomas/gocyclo";
  };
}
