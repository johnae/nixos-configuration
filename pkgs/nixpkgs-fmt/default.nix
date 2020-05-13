{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1ssicdnck8jd35w1q9ldhwkzwrmz9c36jnyvmk0bg43s7978j9wa";

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
