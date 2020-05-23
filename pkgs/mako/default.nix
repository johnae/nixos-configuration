{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, wayland
, scdoc
, makeWrapper
, wayland-protocols
, gdk_pixbuf
, dbus_libs
, pango
, cairo
, git
, systemd
, librsvg
, sources
}:

stdenv.mkDerivation rec {
  name = "${sources.mako.repo}-${version}";
  version = sources.mako.rev;

  src = sources.mako;

  nativeBuildInputs = [ meson ninja pkgconfig git scdoc makeWrapper ];

  buildInputs = [
    wayland
    wayland-protocols
    dbus_libs
    pango
    cairo
    systemd
    gdk_pixbuf
    librsvg
  ];

  ## we handle this elsewhere
  mesonFlags = [
    "-Dsystemd=disabled"
  ];

  postInstall = ''
    wrapProgram $out/bin/mako \
     --set GDK_PIXBUF_MODULE_FILE "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
  '';

  meta = with stdenv.lib; {
    description = "notification daemon for Wayland";
    homepage = "https://mako-project.org/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
