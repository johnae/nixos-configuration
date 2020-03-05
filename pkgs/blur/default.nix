{ stdenv, rustPlatform, fetchFromGitHub }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;

  src = fetchFromGitHub metadata;
  cargoSha256 = "18db34xv9sxnpgg8nl26fk7vi3kvf84lvnwbxjpyz1izw55lingw";

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
