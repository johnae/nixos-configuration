{ stdenv
, meson
, ninja
, pkgconfig
, git
, asciidoc
, libxslt
, docbook_xsl
, scdoc
, wayland
, wayland-protocols
, libxkbcommon
, cairo
, pam
, gdk_pixbuf
, sources
, buildDocs ? true
}:

stdenv.mkDerivation rec {
  name = "${sources.swaylock.repo}-${version}";
  version = sources.swaylock.rev;

  src = sources.swaylock;

  nativeBuildInputs = [ meson ninja pkgconfig git ]
    ++ stdenv.lib.optional buildDocs [ scdoc asciidoc libxslt docbook_xsl ];
  buildInputs = [ wayland wayland-protocols cairo pam gdk_pixbuf libxkbcommon ];

  mesonFlags = [ "-Dauto_features=enabled" ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    inherit (sources.swaylock) description homepage;
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
