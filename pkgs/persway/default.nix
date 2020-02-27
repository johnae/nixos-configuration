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

  cargoSha256 = "02g2vk2awmlzikmd243p63qp0j6gd8lbqbfbnhqjj2xxaxrqqsc6";

  outputs = [ "out" ];

  meta = with stdenv.lib; {
    description = "Small Sway IPC Daemon";
    homepage = "https://github.com/johnae/persway";
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
