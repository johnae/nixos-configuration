{
  stdenv,
  libdot,
  writeText,
  ...
}:

let
  config = writeText "termite-config" ''
    # Copyright (c) 2016-present Arctic Ice Studio <development@arcticicestudio.com>
    # Copyright (c) 2016-present Sven Greb <code@svengreb.de>

    # Project:    Nord Termite
    # Repository: https://github.com/arcticicestudio/nord-termite
    # License:    MIT

    [colors]
    cursor = #d8dee9
    cursor_foreground = #2e3440

    foreground = #d8dee9
    foreground_bold = #d8dee9
    background = rgba(20, 51, 80, 0.95)

    highlight = #4c566a

    color0  = #3b4252
    color1  = #bf616a
    color2  = #a3be8c
    color3  = #ebcb8b
    color4  = #81a1c1
    color5  = #b48ead
    color6  = #88c0d0
    color7  = #e5e9f0
    color8  = #4c566a
    color9  = #bf616a
    color10 = #a3be8c
    color11 = #ebcb8b
    color12 = #81a1c1
    color13 = #b48ead
    color14 = #8fbcbb
    color15 = #eceff4

    [options]
    font = Office Code Pro D Nerd Font, Font Awesome 5 Brands, Font Awesome 5 Free, 14
    scrollback_lines = 20000
  '';

  configLargeFont = writeText "termite-large-font-config" ''
    # Copyright (c) 2016-present Arctic Ice Studio <development@arcticicestudio.com>
    # Copyright (c) 2016-present Sven Greb <code@svengreb.de>

    # Project:    Nord Termite
    # Repository: https://github.com/arcticicestudio/nord-termite
    # License:    MIT

    [colors]
    cursor = #d8dee9
    cursor_foreground = #2e3440

    foreground = #d8dee9
    foreground_bold = #d8dee9
    background = rgba(20, 51, 80, 0.95)

    highlight = #4c566a

    color0  = #3b4252
    color1  = #bf616a
    color2  = #a3be8c
    color3  = #ebcb8b
    color4  = #81a1c1
    color5  = #b48ead
    color6  = #88c0d0
    color7  = #e5e9f0
    color8  = #4c566a
    color9  = #bf616a
    color10 = #a3be8c
    color11 = #ebcb8b
    color12 = #81a1c1
    color13 = #b48ead
    color14 = #8fbcbb
    color15 = #eceff4

    [options]
    font = Office Code Pro D, Font Awesome 5 Brands, Font Awesome 5 Free, 28
    scrollback_lines = 20000
  '';

  configLauncher = writeText "termite-launcher-config" ''
    [colors]
    foreground          = #ffffff
    foreground_bold     = #ffffff
    cursor              = #ffffff
    cursor_foreground   = #ffffff
    background = rgba(0.0, 75.0, 70.0, 0.85)

    [options]
    font = Roboto Mono Regular 28
    scrollback_lines = 20000
  '';

in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/termite"; }}
      ${libdot.copy { path = config; to = ".config/termite/config";  }}
      ${libdot.copy { path = configLargeFont; to = ".config/termite/config-large-font";  }}
      ${libdot.copy { path = configLauncher; to = ".config/termite/config-launcher";  }}
    '';
  }
