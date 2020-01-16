{
  stdenv,
  lib,
  libdot,
  writeText,
  curl,
  jq,
  settings,
  ...
}:

let
  config = settings.i3status-rust;
  theme = settings.theme;
  check-nixos-version = libdot.writeStrictShellScriptBin "check-nixos-version" ''
    CURRENT=$(${curl}/bin/curl -sS https://howoldis.herokuapp.com/api/channels | \
              ${jq}/bin/jq -r '.[] | select(.name == "nixos-unstable") | "\(.link) \(.time)"')
    AGE_SECS=$(echo "$CURRENT" | awk '{print $2}')
    AGE_DAYS="$(echo "$AGE_SECS / 60 / 60 / 24" | bc)"
    if [ "$AGE_DAYS" = "1" ]; then
      AGE_DAYS="$AGE_DAYS day ago"
    else
      AGE_DAYS="$AGE_DAYS days ago"
    fi
    LATEST=$(echo "$CURRENT" | awk '{print $1}' | awk -F'.' '{print $NF}')
    LOCAL=$(awk -F'.' '{print $2}' < ~/.nix-defexpr/channels_root/nixos/.version-suffix)
    if [ "$LOCAL" != "$LATEST" ]; then
      echo " $LATEST ($AGE_DAYS)"
    else
      echo " $LATEST ($AGE_DAYS)"
    fi
  '';
  i3statusconf = writeText "i3status-rust.conf" ''
     [theme]
     name = "modern"
     [theme.overrides]
     idle_bg = "${theme.base03}DD"
     idle_fg = "${theme.base05}"
     info_bg = "${theme.base08}DD"
     info_fg = "${theme.base00}"
     good_bg = "${theme.base0A}DD"
     good_fg = "${theme.base00}"
     warning_bg = "${theme.base0D}DD"
     warning_fg = "${theme.base00}"
     critical_bg = "${theme.base0B}DD"
     critical_fg = "${theme.base04}"

     [icons]
     name = "awesome"
     [icons.overrides]
     cpu = "  "

     [[block]]
     block = "custom"
     command = "${check-nixos-version}/bin/check-nixos-version"
     interval = 600

     [[block]]
     block = "cpu"
     interval = 1

     [[block]]
     block = "backlight"

     [[block]]
     block = "battery"
     interval = 10
     format = "{percentage}% {time}"

     [[block]]
     block = "net"
     device = "wlan0"
     ssid = true
     signal_strength = true
     ip = false
     speed_up = true
     graph_up = false
     interval = 5

     [[block]]
     block = "music"
     buttons = ["play", "prev" ,"next"]

     [[block]]
     block = "sound"

     ## headphones
     [[block]]
     block = "bluetooth"
     mac = "04:52:C7:5F:CC:B6"

     ## mouse
     [[block]]
     block = "bluetooth"
     mac = "D5:17:1A:80:22:AA"

     [[block]]
     block = "time"
     interval = 1
     format = "%b-%d %H:%M:%S"
  '';

in

  i3statusconf
