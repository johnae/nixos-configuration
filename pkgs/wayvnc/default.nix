{ stdenv
, pkgconfig
, meson
, ninja
, wayland
, wayland-protocols
, libxkbcommon
, libvncserver
, libpthreadstubs
, pixman
, aml
, libglvnd
, neatvnc
, libX11
, libdrm
, sources
}:

stdenv.mkDerivation rec {
  name = "wayvnc-${version}";
  version = sources.wayvnc.rev;

  src = sources.wayvnc;

  #patches = [
  #  ./disable-input.patch
  #];

  nativeBuildInputs = [ pkgconfig meson ninja ];
  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    libvncserver
    libpthreadstubs
    pixman
    aml
    libglvnd
    neatvnc
    libX11
    libdrm
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    inherit (sources.wayvnc) description homepage;
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
