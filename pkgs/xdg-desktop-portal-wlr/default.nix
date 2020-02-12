# { stdenv, fetchFromGitHub, meson, ninja, pkgconfig, wayland, scdoc, makeWrapper
#, wayland-protocols, gdk_pixbuf, dbus_libs, pango, cairo, git, systemd, librsvg
#}:

{ stdenv, fetchFromGitHub, meson, ninja, pkgconfig, scdoc, makeWrapper
, dbus_libs, git, cairo, pango, wayland, wayland-protocols, systemd, gdk_pixbuf
}:

let

  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);

in stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig git scdoc makeWrapper ];

  buildInputs = [ cairo pango wayland wayland-protocols systemd gdk_pixbuf ];
  #buildInputs = [
  #  wayland wayland-protocols dbus_libs
  #  pango cairo systemd gdk_pixbuf librsvg
  #];

  #postInstall = ''
  #  wrapProgram $out/bin/mako \
  #   --set GDK_PIXBUF_MODULE_FILE "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
  #'';

  meta = with stdenv.lib; {
    description = "screen sharing for wayland";
    homepage = "https://github.com/emersion/xdg-desktop-portal-wlr";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
