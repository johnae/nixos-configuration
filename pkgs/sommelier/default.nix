{ stdenv
, fetchFromGitHub
, meson
, ninja
, systemd
, xwayland
, pkgconfig
, wayland
, wayland-protocols
, libxkbcommon
, pixman
, xorg
, mesa
}:

let

  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);

in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ pkgconfig meson ninja ];

  buildInputs = [
    xorg.libxcb
    xorg.libXrender
    xorg.libXtst
    wayland
    wayland-protocols
    libxkbcommon
    systemd
    xwayland
    libxkbcommon
    pixman
    mesa
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "wayland in wayland";
    homepage = "https://github.com/akvadrako/sommelier";
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
