{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.blur.repo;
  version = sources.blur.rev;

  src = sources.blur;
  cargoSha256 = "0000000000000000000000000000000000000000000000000000";

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Blurring etc for sway lock screen";
    homepage = "https://github.com/johnae/blur";
    license = licenses.mit;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
