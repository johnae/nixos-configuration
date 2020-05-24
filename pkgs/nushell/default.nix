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

  cargoSha256 = "1753k0ngyn27prbrwkypfypacd04nnjvwykgisl2iivj2v2di291";

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
