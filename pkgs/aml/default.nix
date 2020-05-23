{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, sources
}:
stdenv.mkDerivation rec {
  name = "${sources.aml.repo}-${version}";
  version = sources.aml.rev;

  src = sources.aml;

  nativeBuildInputs = [ meson ninja pkgconfig ];

  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "Andri's Main Loop";
    homepage = "https://github.com/any1/aml";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
