{ stdenv
, coreutils
, gnused
, meson
, ninja
, pkgconfig
, wayland
, wayland-protocols
, git
, systemd
, sources
}:

stdenv.mkDerivation rec {
  name = "${sources.wl-clipboard.repo}-${version}";
  version = sources.wl-clipboard.rev;

  src = sources.wl-clipboard;

  preConfigure = ''
    echo "Fixing cat path..."
    ${gnused}/bin/sed -i"" 's|\(/bin/cat\)|${coreutils}\1|g' src/wl-paste.c
  '';

  mesonFlags = [
    "-Dfishcompletiondir=no"
  ];

  nativeBuildInputs = [ meson ninja pkgconfig git ];
  buildInputs = [ wayland wayland-protocols ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    inherit (sources.wl-clipboard) description homepage;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
