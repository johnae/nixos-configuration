{stdenv, libdot, writeText, ...}:

let
  config = writeText "gsimplecal-config" ''
    show_calendar = 1
    show_timezones = 1
    mark_today = 1
    show_week_numbers = 1
    close_on_unfocus = 0
    external_viewer = sunbird -showdate "%Y-%m-%d"
    clock_format = %a %d %b %H:%M
    force_lang = en_GB.utf8
    mainwindow_decorated = 0
    mainwindow_leep_above = 1
    mainwindow_sticky = 0
    mainwindow_skip_taskbar = 1
    mainwindow_resizable = 0
    mainwindow_position = mouse
    mainwindow_xoffset = -40
    mainwindow_yoffset = -152
    clock_label = Local
    clock_tz = :Europe/Stockholm
    clock_label = UTC
    clock_tz = :UTC
    clock_label = London
    clock_tz = :Europe/London
    clock_label = New York
    clock_tz = :America/New_York
    clock_label = Los Angeles
    clock_tz = :America/Los_Angeles
  '';
in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/gsimplecal"; }}
      ${libdot.copy { path = config; to = ".config/gsimplecal/config"; }}
    '';
  }