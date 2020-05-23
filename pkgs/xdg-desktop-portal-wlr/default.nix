{ stdenv
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
, libdrm
, systemd
, gdk_pixbuf
, sources
}:

stdenv.mkDerivation rec {
  name = "${sources.xdg-desktop-portal-wlr.repo}-${version}";
  version = sources.xdg-desktop-portal-wlr.rev;

  src = sources.xdg-desktop-portal-wlr;

  nativeBuildInputs = [ meson ninja pkgconfig git scdoc makeWrapper ];

  buildInputs = [
    cairo
    pango
    wayland
    wayland-protocols
    systemd
    gdk_pixbuf
    pipewire
    libdrm
  ];

  meta = with stdenv.lib; {
    inherit (sources.xdg-desktop-portal-wlr) description homepage;
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
