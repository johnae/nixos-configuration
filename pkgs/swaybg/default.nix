{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkgconfig
, git
, scdoc
, wayland
, wayland-protocols
, cairo
, gdk_pixbuf
, buildDocs ? true
}:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  name = "${metadata.repo}-${version}";
  version = metadata.rev;

  src = fetchFromGitHub metadata;

  nativeBuildInputs = [ meson ninja pkgconfig git ]
  ++ stdenv.lib.optional buildDocs [ scdoc ];
  buildInputs = [ wayland wayland-protocols cairo gdk_pixbuf ];

  mesonFlags = [ "-Dauto_features=enabled" ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Sway's idle management daemon.";
    homepage = "http://swaywm.org";
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
