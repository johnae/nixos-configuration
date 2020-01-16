{ stdenv, fetchgit, wget, perl, cacert }:

stdenv.mkDerivation rec {
  version = "0.9.7-pre";
  name = "spook-${version}";
  SPOOK_VERSION = version;

  src = fetchgit {
    url = https://github.com/johnae/spook;
    rev = "11230f63b740afd77cee710c5dcb27161e7c50ca";
    sha256 = "1y8rx12ivd9n703haas9wm0b0bsqy9qiyppwgwb62pp6gqijf14q";
    fetchSubmodules = true;
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    make install PREFIX=$out
    runHook postInstall
  '';

  buildInputs = [ wget perl cacert ];

  meta = {
    description = "Lightweight evented utility for monitoring file changes and more";
    homepage = https://github.com/johnae/spook;
    license = "MIT";
  };

}
