{ stdenv
, fetchpatch
, meson
, ninja
, pkgconfig
, wayland
, libGL
, wayland-protocols
, libinput
, libxkbcommon
, pixman
, xcbutilwm
, libX11
, libcap
, xcbutilimage
, xcbutilerrors
, mesa_noglu
, libpng
, sources
}:

stdenv.mkDerivation rec {
  name = sources.wlroots.repo;
  version = sources.wlroots.rev;

  src = sources.wlroots;

  outputs = [ "out" ];

  nativeBuildInputs = [ meson ninja pkgconfig ];

  mesonFlags = [
    "-Dlibcap=enabled"
    "-Dlogind-provider=systemd"
    "-Dxwayland=enabled"
    "-Dx11-backend=enabled"
    "-Dxcb-icccm=enabled"
    "-Dxcb-errors=enabled"
    "-Dfreerdp=disabled"
  ];

  buildInputs = [
    wayland
    libGL
    wayland-protocols
    libinput
    libxkbcommon
    pixman
    xcbutilwm
    libX11
    libcap
    xcbutilimage
    xcbutilerrors
    mesa_noglu
    libpng
  ];

  meta = with stdenv.lib; {
    inherit (sources.wlroots) description homepage;
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
