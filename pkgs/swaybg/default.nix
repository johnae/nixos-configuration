{ stdenv
, meson
, ninja
, pkgconfig
, git
, scdoc
, wayland
, wayland-protocols
, cairo
, gdk_pixbuf
, sources
, buildDocs ? true
}:

stdenv.mkDerivation rec {
  name = "${sources.swaybg.repo}-${version}";
  version = sources.swaybg.rev;

  src = sources.swaybg;

  nativeBuildInputs = [ meson ninja pkgconfig git ]
    ++ stdenv.lib.optional buildDocs [ scdoc ];
  buildInputs = [ wayland wayland-protocols cairo gdk_pixbuf ];

  mesonFlags = [ "-Dauto_features=enabled" ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    inherit (sources.swaybg) description homepage;
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
