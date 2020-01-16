{stdenv, libdot, writeText, settings, ...}:

with settings.xresources;

let

  config = writeText "Xresources" ''
    ! Fonts {{{
    Xft.lcdfilter: lcddefault
    Xft.autohint: 0
    Xft.antialias: 1
    Xft.hinting:   1
    Xft.rgba:      rgb
    Xft.hintstyle: hintslight
    Xft.dpi: ${dpi}
    ! }}}

    ! rofi config
    rofi.color-enabled: true
    rofi.color-normal: ${rofiColorNormal}
    rofi.color-window: ${rofiColorWindow}
    rofi.separator-style: none
    rofi.lines: 3
    rofi.bw: 0
    rofi.hide-scrollbar: true
    rofi.eh: 2
    rofi.padding: 300
    rofi.fullscreen: true
    rofi.opacity: 85
    rofi.matching: fuzzy
    rofi.sort: true
    rofi.sorting-method: fzf
    rofi.font: ${rofiFont}
  '';

in

  {
    __toString = self: ''
      ${libdot.copy { path = config; to = ".Xresources"; }}
    '';
  }