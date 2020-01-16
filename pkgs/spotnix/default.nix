
{ stdenv, rustPlatform, fetchFromGitHub, pkgconfig, openssl }:

let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1dc8bwgbl4f48c6mr5nqabihi486vcp52m2jvpwlp8i8ldqzfn40";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
     openssl
  ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Spotify for UNIX";
    homepage = https://github.com/johnae/spotnix;
    license = licenses.gpl3;
    maintainers = [{
      email = "john@insane.se";
      github = "johnae";
      name = "John Axel Eriksson";
    }];
  };
}
