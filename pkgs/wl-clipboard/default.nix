{ stdenv
, fetchFromGitHub
, coreutils
, gnused
, meson
, ninja
, pkgconfig
, wayland
, wayland-protocols
, git
, systemd
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

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
    description = "Hacky clipboard manager for Wayland";
    homepage = "https://github.com/bugaevc/wl-clipboard";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ primeos ]; # Trying to keep it up-to-date.
  };
}
