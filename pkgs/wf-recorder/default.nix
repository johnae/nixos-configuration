{ stdenv
, meson
, ninja
, pkgconfig
, wayland
, scdoc
, ffmpeg
, wayland-protocols
, libpulseaudio
, sources
}:

stdenv.mkDerivation rec {
  name = "${sources.wf-recorder.repo}-${version}";
  version = sources.wf-recorder.rev;

  src = sources.wf-recorder;

  nativeBuildInputs = [ meson ninja pkgconfig scdoc ];

  buildInputs = [ wayland wayland-protocols ffmpeg libpulseaudio ];

  mesonFlags = [ "-Dopencl=disabled" ];

  meta = with stdenv.lib; {
    inherit (sources.wf-recorder) description homepage;
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
