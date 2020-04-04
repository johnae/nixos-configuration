{ stdenv
, fetchFromGitHub
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
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "wayvnc-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

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
    description = "VNC server for wlroots based Wayland compositors. It attaches to a running Wayland session, creates virtual input devices and exposes a single display via the RFB protocol.";
    homepage = "https://github.com/any1/wayvnc";
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
