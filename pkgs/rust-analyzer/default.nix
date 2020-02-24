{ stdenv, lib, fetchFromGitHub, pkgs }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
  nightlyRustPlatform =
    let
      nightly = pkgs.rustChannelOf {
        date = "2020-02-05";
        channel = "nightly";
      };
    in
      pkgs.makeRustPlatform {
        rustc = nightly.rust;
        cargo = nightly.rust;
      };
in
  with nightlyRustPlatform;
  buildRustPackage rec {
    pname = metadata.repo;
    version = metadata.rev;
    doCheck = false;

    src = fetchFromGitHub metadata;

    cargoSha256 = "0000000000000000000000000000000000000000000000000000";

    outputs = [ "out" ];

    meta = with stdenv.lib; {
      description = "Rust Analyzer";
      homepage = "https://github.com/rust-analyzer/rust-analyzer";
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
