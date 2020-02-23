{ stdenv, rustPlatform, fetchFromGitHub, lib, bash, jq, grim, sway, swaylock, mkStrictShellScript }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
  blur = rustPlatform.buildRustPackage rec {
    pname = metadata.repo;
    version = metadata.rev;

    src = fetchFromGitHub metadata;
    cargoSha256 = "16kg8cb74xzn1bsadf265ifc12pgddf5fzkgd9csbwlpyf8cmzxk";

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
  };
in
mkStrictShellScript {
  name = "swaylock-dope";
  src = ./swaylock-dope;
  substitutions = { inherit stdenv blur bash jq grim sway swaylock; };
}
