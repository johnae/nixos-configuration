{ buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {

  name = "bingo-${version}";
  version = "2019-03-11";
  goPackagePath = "github.com/saibing/bingo";

  src = fetchFromGitHub {
    owner = "saibing";
    repo = "bingo";
    rev = "d2248939f85eb66d16f967a49568ec9b7e7d3227";
    sha256 = "1bsgh2zbndy51i040jkh9fxg17bir9hsyjkbs8d10ya0gxcwdcm7";
  };

  preBuild = ''
    rm -rf go/src/github.com/saibing/bingo/langserver/internal/refs/testdata
  '';

  goDeps = ./deps.nix;

  meta = {
    description = "Bingo a go language server";
    homePage = "https://github.com/saibing/bingo";
  };
}
