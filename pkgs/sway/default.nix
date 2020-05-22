{ stdenv
, meson
, ninja
, pkgconfig
, scdoc
, freerdp
, wayland
, wayland-protocols
, libxkbcommon
, pcre
, json_c
, dbus
, pango
, cairo
, libinput
, libcap
, pam
, gdk_pixbuf
, libevdev
, wlroots
, sources
, buildDocs ? true
}:
stdenv.mkDerivation rec {
  name = "${sources.sway.repo}-${version}";
  version = sources.sway.rev;

  src = sources.sway;

  nativeBuildInputs = [ pkgconfig meson ninja ]
    ++ stdenv.lib.optional buildDocs scdoc;

  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    pcre
    json_c
    dbus
    pango
    cairo
    libinput
    libcap
    pam
    gdk_pixbuf
    freerdp
    wlroots
    libevdev
    scdoc
  ];

  postPatch = ''
    sed -iE "s/version: '1.0',/version: '${version}',/" meson.build
  '';

  mesonFlags = [
    "-Ddefault-wallpaper=false"
    "-Dxwayland=enabled"
    "-Dgdk-pixbuf=enabled"
    "-Dtray=enabled"
  ] ++ stdenv.lib.optional buildDocs "-Dman-pages=enabled";

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    inherit (sources.sway) description homepage;
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
