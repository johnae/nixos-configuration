{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "07qksrjl0qa9ln181vg0iy5anck891lcld5bp6x3js11zwsh0xpr";

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
