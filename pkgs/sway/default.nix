{ stdenv, fetchFromGitHub
, meson, ninja
, pkgconfig, scdoc, freerdp
, wayland, wayland-protocols, libxkbcommon
, pcre, json_c, dbus, pango, cairo, libinput
, libcap, pam, gdk_pixbuf, libevdev, wlroots
, buildDocs ? true
}:

let

  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);

in

  stdenv.mkDerivation rec {
    name = "${metadata.repo}-${version}";
    version = metadata.rev;

    src = fetchFromGitHub metadata;

    nativeBuildInputs = [
      pkgconfig meson ninja
    ] ++ stdenv.lib.optional buildDocs scdoc;

    buildInputs = [
      wayland wayland-protocols libxkbcommon pcre json_c dbus
      pango cairo libinput libcap pam gdk_pixbuf freerdp
      wlroots libevdev scdoc
    ];

    postPatch = ''
      sed -iE "s/version: '1.0',/version: '${version}',/" meson.build
    '';

     mesonFlags = [
       "-Ddefault-wallpaper=false" "-Dxwayland=enabled"
       "-Dgdk-pixbuf=enabled" "-Dtray=enabled"
     ] ++ stdenv.lib.optional buildDocs "-Dman-pages=enabled";

    enableParallelBuilding = true;

    meta = with stdenv.lib; {
      description = "i3-compatible window manager for Wayland";
      homepage    = http://swaywm.org;
      license     = licenses.mit;
      platforms   = platforms.linux;
      maintainers = with maintainers; [ {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      } ];
    };
  }
