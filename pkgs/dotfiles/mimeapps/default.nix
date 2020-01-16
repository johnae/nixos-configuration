{stdenv, libdot, writeText, ...}:

let
  config = writeText "mimeapps-config" ''
    [Added Associations]
    image/jpeg=gimp.desktop;
    text/plain=org.gnome.gedit.desktop;
    application/pdf=evince.desktop;
    x-scheme-handler/http=firefox.desktop;
    x-scheme-handler/https=firefox.desktop;
    x-scheme-handler/ftp=firefox.desktop;
    x-scheme-handler/chrome=firefox.desktop;
    text/html=firefox.desktop;
    application/x-extension-htm=firefox.desktop;
    application/x-extension-html=firefox.desktop;
    application/x-extension-shtml=firefox.desktop;
    application/xhtml+xml=firefox.desktop;
    application/x-extension-xhtml=firefox.desktop;
    application/x-extension-xht=firefox.desktop;
    image/png=gimp.desktop;

    [Default Applications]
    x-scheme-handler/http=firefox.desktop
    x-scheme-handler/https=firefox.desktop
    x-scheme-handler/ftp=firefox.desktop
    x-scheme-handler/chrome=firefox.desktop
    text/html=firefox.desktop
    application/x-extension-htm=firefox.desktop
    application/x-extension-html=firefox.desktop
    application/x-extension-shtml=firefox.desktop
    application/xhtml+xml=firefox.desktop
    application/x-extension-xhtml=firefox.desktop
    application/x-extension-xht=firefox.desktop
  '';

in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config"; }}
      ${libdot.copy { path = config; to = ".config/mimeapps.list"; }}
    '';
  }