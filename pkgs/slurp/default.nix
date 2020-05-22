{ stdenv
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
, sources
}:
stdenv.mkDerivation rec {
  name = "${sources.slurp.repo}-${version}";
  version = sources.slurp.rev;

  src = sources.slurp;

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
    inherit (sources.slurp) description homepage;
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
