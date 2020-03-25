{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, wayland
, wayland-protocols
, cairo
, libxkbcommon
, libjpeg
, git
, systemd
, scdoc
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig git scdoc ];
  buildInputs = [
    wayland
    wayland-protocols
    cairo
    libjpeg
    libxkbcommon
    systemd
  ];

  meta = with stdenv.lib; {
    description = "select a region in a wayland compositor";
    homepage = "https://wayland.emersion.fr/slurp/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
