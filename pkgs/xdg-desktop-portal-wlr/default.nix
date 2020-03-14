{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, scdoc
, makeWrapper
, dbus_libs
, git
, cairo
, pango
, wayland
, wayland-protocols
, pipewire
, systemd
, gdk_pixbuf
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig git scdoc makeWrapper ];

  buildInputs = [ cairo pango wayland wayland-protocols systemd gdk_pixbuf pipewire ];

  meta = with stdenv.lib; {
    description = "screen sharing for wayland";
    homepage = "https://github.com/emersion/xdg-desktop-portal-wlr";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
