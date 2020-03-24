{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "0h7fyzwaqvpvn1pv9ix23qni0bhjfdf395k2abcxmr4arvvl6n51";

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
