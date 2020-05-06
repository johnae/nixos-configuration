{ stdenv
, lib
, fetchFromGitHub
, rustPlatform
, openssl
, pkg-config
, python3
, xorg
, withStableFeatures ? true
, withTestBinaries ? true
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
rustPlatform.buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;
  doCheck = false;

  src = fetchFromGitHub metadata;

  cargoSha256 = "09gpalkmdzbysy6yhqd7xj8qacvxff4nraw9cwyriscnfilyhcc7";

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
    description = "A modern shell written in Rust";
    homepage = "https://www.nushell.sh/";
    license = licenses.mit;
    maintainers = with maintainers; [ filalex77 marsam ];
    platforms = [ "x86_64-linux" "i686-linux" "x86_64-darwin" ];
  };

  passthru = { shellPath = "/bin/nu"; };
}
