{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, wayland
, scdoc
, ffmpeg
, wayland-protocols
, libpulseaudio
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig scdoc ];

  buildInputs = [ wayland wayland-protocols ffmpeg libpulseaudio ];

  mesonFlags = [ "-Dopencl=disabled" ];

  meta = with stdenv.lib; {
    description = "Screen Recorder for Wlroots compositors";
    homepage = "https://github.com/ammen99/wf-recorder";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
