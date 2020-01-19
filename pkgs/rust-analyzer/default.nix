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

    cargoSha256 = "0qsil1y2gv8h75x3mnp6h7b295k3icwjhmhriy3bv49qm11ffz0w";

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
