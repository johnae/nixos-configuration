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

    cargoSha256 = "1n4d2a2q2z87kw2f0wnc2yqd12w19xpcrkldf6yp428s6fqp5nhp";

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
