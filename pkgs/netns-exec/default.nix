{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1sdb2li5hcll6x0ip15rigq8kkd9s22sfbz3278y9jdf0fcsm5in";

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Execute process within Linux network namespace";
    homepage = "https://github.com/johnae/netns-exec";
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
