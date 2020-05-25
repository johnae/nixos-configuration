{ stdenv
, lib
, rustPlatform
, openssl
, pkg-config
, python3
, xorg
, sources
, withStableFeatures ? true
, withTestBinaries ? true
}:
rustPlatform.buildRustPackage rec {
  pname = sources.nushell.repo;
  version = sources.nushell.rev;
  doCheck = false;

  src = sources.nushell;

  cargoSha256 = "1nc9gcq9ynpsdzlb53d2vb2qr0bzkn3yfxlzq4ygk81ni9gy8dq7";

  nativeBuildInputs = [ pkg-config python3 ];

  buildInputs = [ openssl xorg.libX11 ];

  cargoBuildFlags = lib.optional withStableFeatures "--features stable";

  cargoTestFlags = lib.optional withTestBinaries "--features test-bins";

  preCheck = ''
    export HOME=$TMPDIR
  '';

  checkPhase = ''
    runHook preCheck
    echo "Running cargo cargo test ${
      lib.strings.concatStringsSep " " cargoTestFlags
    } -- ''${checkFlags} ''${checkFlagsArray+''${checkFlagsArray[@]}}"
    cargo test ${
      lib.strings.concatStringsSep " " cargoTestFlags
    } -- ''${checkFlags} ''${checkFlagsArray+"''${checkFlagsArray[@]}"}
    runHook postCheck
  '';

  meta = with lib; {
    inherit (sources.nushell) description homepage;
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" "x86_64-darwin" ];
  };

  passthru = { shellPath = "/bin/nu"; };
}
