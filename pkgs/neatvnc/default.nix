{ stdenv
, fetchFromGitHub
, meson
, pkg-config
, ninja
, pixman
, aml
, gnutls
, libdrm
, libjpeg_turbo
, zlib
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  pname = "neatvnc-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson pkg-config ninja ];
  buildInputs = [
    pixman
    aml
    gnutls
    libdrm
    libjpeg_turbo
    zlib
  ];

  meta = with stdenv.lib; {
    description = "A VNC server library";
    longDescription = ''
      This is a liberally licensed VNC server library that's intended to be
      fast and neat. Goals:
      - Speed
      - Clean interface
      - Interoperability with the Freedesktop.org ecosystem
    '';
    inherit (src.meta) homepage;
    license = licenses.isc;
    platforms = platforms.linux;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
