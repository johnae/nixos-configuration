{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig ];

  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "Andri's Main Loop";
    homepage = "https://github.com/any1/aml";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
