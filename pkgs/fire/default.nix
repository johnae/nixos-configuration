{ stdenv, fetchFromGitHub, ghc }:

stdenv.mkDerivation rec {
  version = "1.0.1";
  name = "fire-${version}";

  src = fetchFromGitHub {
    owner = "johnae";
    repo = "fire";
    rev = "2a64559b4364828b651305d89b76ba3f03661355";
    sha256 = "1lg6yvzqs34s7lmdw2fvdz6zk3g4lbgfzrcb27fdv0kqsnhfhg3z";
  };

  buildPhase = ''
    ghc -O2 fire.hs
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp fire $out/bin/
    runHook postInstall
  '';

  buildInputs = [ ghc ];

  meta = {
    description = "Simple launcher (creates new process group for exec'd process)";
    homepage = https://github.com/johnae/fire;
    license = "MIT";
  };
}
