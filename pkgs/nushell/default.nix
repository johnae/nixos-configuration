{ stdenv,
  lib,
  fetchFromGitHub,
  openssl,
  xorg,
  pkg-config,
  python3,
  pkgs
}:

let

  metadata = builtins.fromJSON(builtins.readFile ./metadata.json);
  nightlyRustPlatform =
    let
      nightly = pkgs.rustChannelOf {
        date = "2019-12-07";
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

    nativeBuildInputs = [
      pkg-config python3
    ];

    buildInputs = [
      openssl xorg.libxcb xorg.libX11
    ];

    cargoSha256 = "0bdxlbl33kilp9ai40dvdzlx9vcl8r21br82r5ljs2pg521jd66p";

    cargoBuildFlags = [ "--all-features" ];

    preCheck = ''
      export HOME=$TMPDIR
    '';

    meta = with stdenv.lib; {
      description = "NuShell";
      homepage = https://github.com/nushell/nushell;
      license = licenses.mit;
      maintainers = [{
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }];
    };

    passthru = {
      shellPath = "/bin/nu";
    };
  }
