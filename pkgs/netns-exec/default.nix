{ stdenv, rustPlatform, fetchFromGitHub}:

let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1wzg153b9fvv8cj5g2xpv2ggs3zr3973k9af9wvpjlkpacnax54j";

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
