{ stdenv, lib, fetchFromGitHub, rustPlatform }:

with rustPlatform;
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = metadata.owner;
    repo = pname;
    rev = "${version}";
    sha256 = metadata.sha256;
  };

  cargoSha256 = "1ndw5gbdicany76ilhhrayzisgfgsmzxf3kz8xr6sx26bqchcq13";

  outputs = [ "out" ];

  meta = with stdenv.lib; {
    description = "The ION shell from Redox OS";
    homepage = "https://github.com/redox-os/ion";
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
