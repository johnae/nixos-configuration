{ stdenv,
  lib,
  fetchFromGitHub,
  pkgs
}:

let

  metadata = builtins.fromJSON(builtins.readFile ./metadata.json);
  nightlyRustPlatform =
    let
      nightly = pkgs.rustChannelOf {
        date = "2019-12-15";
        channel = "nightly";
      };
    in
    pkgs.makeRustPlatform {
      rustc = nightly.rust;
      cargo = nightly.rust;
    };

in

  with nightlyRustPlatform; buildRustPackage rec {
    pname = metadata.repo;
    version = metadata.rev;
    doCheck = false;

    src = fetchFromGitHub metadata;

    cargoSha256 = "1nh0cx0rv0liszasfgflc50j7zfgr5qs8ssvsxqsafrvdwpcksbh";

    outputs = [ "out" ];

    meta = with stdenv.lib; {
      description = "Rust Analyzer";
      homepage = https://github.com/rust-analyzer/rust-analyzer;
      license = licenses.mit;
      maintainers = [{
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }];
    };
  }
