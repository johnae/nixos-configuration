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

  cargoSha256 = "1y5j7391a1y5r1bj2s4ywg90yfbmdw1fvwd95nfpgq3x1dnclgas";

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
