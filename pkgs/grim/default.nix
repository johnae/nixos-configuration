{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, wayland
, wayland-protocols
, cairo
, libjpeg
, git
, systemd
, sources
}:

stdenv.mkDerivation rec {
  name = "grim-${sources.grim.rev}";
  version = sources.grim.rev;

  src = sources.grim;

  nativeBuildInputs = [ meson ninja pkgconfig git ];
  buildInputs = [ wayland wayland-protocols cairo libjpeg systemd ];

  meta = with stdenv.lib; {
    description = "image grabber for wayland compositors";
    homepage = "https://wayland.emersion.fr/grim/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
