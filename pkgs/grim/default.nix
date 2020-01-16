{ stdenv, fetchFromGitHub, meson, ninja, pkgconfig, wayland,
  wayland-protocols, cairo, libjpeg, git, systemd
}:

stdenv.mkDerivation rec {
  name = "grim-${version}";
  version = "bced8c88165bd15cf97d3b55a9241b0a6ee1fe3c";

  src = fetchFromGitHub {
    owner = "emersion";
    repo = "grim";
    rev = version;
    sha256 = "1cgqpw7y1yj0b4lcm7727i2xaah0j4bcg48n3xy1cl6pij2zajsd";
  };

  nativeBuildInputs = [
    meson ninja pkgconfig git
  ];
  buildInputs = [
    wayland wayland-protocols cairo libjpeg systemd
  ];

  meta = with stdenv.lib; {
    description = "image grabber for wayland compositors";
    homepage    = https://wayland.emersion.fr/grim/;
    license     = licenses.mit;
    platforms   = platforms.linux;
  };
}