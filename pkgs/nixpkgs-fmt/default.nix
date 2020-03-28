{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1vxahl0bp4yfyayinjc2f6npq961xcwqx0xg80b5185bb649d8ry";

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Nix code formatter for nixpkgs";
    homepage = "https://github.com/nix-community/nixpkgs-fmt";
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
