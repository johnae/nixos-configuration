{
  stdenv
, lib
, libdot
, writeText
, settings
, playerctl
, procps
, ...
}:

with lib;
with libdot;
with settings;

let

  style = writeText "waybar-style.css" ''
    * {
      border: ${waybar.default.border};
      border-radius: ${waybar.default.border-radius};
      font-family: ${waybar.default.font-family};
      font-weight: ${waybar.default.font-weight};
      font-size: ${waybar.default.font-size};
      min-height: ${waybar.default.min-height};
    }

    window#waybar {
        background: rgba(43, 48, 59, 0.8);
        color: white;
    }

    #window {
        font-weight: bold;
    }
    /*
    #workspaces {
        padding: 0 5px;
    }
    */

    #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: white;
        border-top: 2px solid transparent;
    }

    #workspaces button.focused {
        color: rgb(246, 201, 169);
        border-top: 2px solid rgb(246, 201, 169);
    }

    #mode {
        background: #64727D;
        border-bottom: 3px solid white;
    }

    #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
        padding: 0 6px;
        margin: 0 4px;
    }

    #clock {
        font-weight: bold;
    }

    #battery {
    }

    #battery icon {
        color: red;
    }

    #battery.charging {
    }

    @keyframes blink {
        to {
            background-color: #ffffff;
            color: black;
        }
    }

    #battery.warning:not(.charging) {
        color: white;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }

    #cpu {
    }

    #memory {
    }

    #network {
    }

    #network.disconnected {
        background: #f53c3c;
    }

    #pulseaudio {
    }

    #pulseaudio.muted {
    }

    #custom-spotify {
        background: rgba(102, 204, 153, 0.7);
        color: #202020;
    }

    #tray {
        background-color: #2980b9;
    }

  '';

  #style = writeText "waybar-style.css" ''
  #  * {
  #      border: ${waybar.default.border};
  #      border-radius: ${waybar.default.border-radius};
  #      font-family: ${waybar.default.font-family};
  #      font-weight: ${waybar.default.font-weight};
  #      font-size: ${waybar.default.font-size};
  #      min-height: ${waybar.default.min-height};
  #  }

  #  window#waybar {
  #      background: rgba(43, 48, 59, 0.7);
  #      border-bottom: 3px solid rgba(100, 114, 125, 0.5);
  #      color: white;
  #  }

  #  /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
  #  #workspaces button {
  #      padding: 0 5px;
  #      background: transparent;
  #      color: white;
  #      border-bottom: 3px solid transparent;
  #  }

  #  #workspaces button.focused {
  #      background: #64727D;
  #      border-bottom: 3px solid white;
  #  }

  #  #mode {
  #      background: #64727D;
  #      border-bottom: 3px solid white;
  #  }

  #  #clock, #battery, #cpu, #memory, #backlight, #network, #pulseaudio, #custom-spotify, #tray, #mode, #idle_inhibitor {
  #      padding: 0 10px;
  #      margin: 0 5px;
  #  }

  #  #clock {
  #      background-color: #64727D;
  #  }

  #  #battery {
  #      background-color: #ffffff;
  #      color: black;
  #  }

  #  #battery.charging {
  #      color: white;
  #      background-color: #26A65B;
  #  }

  #  @keyframes blink {
  #      to {
  #          background-color: #ffffff;
  #          color: black;
  #      }
  #  }

  #  #battery.critical:not(.charging) {
  #      background: #f53c3c;
  #      color: white;
  #      animation-name: blink;
  #      animation-duration: 0.5s;
  #      animation-timing-function: linear;
  #      animation-iteration-count: infinite;
  #      animation-direction: alternate;
  #  }

  #  #cpu {
  #      background: #2ecc71;
  #      color: #000000;
  #  }

  #  #memory {
  #      background: #9b59b6;
  #  }

  #  #backlight {
  #      background: #90b1b1;
  #  }

  #  #network {
  #      background: #2980b9;
  #  }

  #  #network.disconnected {
  #      background: #f53c3c;
  #  }

  #  #pulseaudio {
  #      background: #f1c40f;
  #      color: black;
  #  }

  #  #pulseaudio.muted {
  #      background: #90b1b1;
  #      color: #2a5c45;
  #  }

  #  #custom-spotify {
  #      background: #66cc99;
  #      color: #2a5c45;
  #  }

  #  #tray {
  #      background-color: #2980b9;
  #  }

  #  #idle_inhibitor {
  #      background-color: #2d3436;
  #  }
  #'';

  playerstatus = writeStrictShellScriptBin "playerstatus" ''
    player_status="$(${playerctl}/bin/playerctl status 2> /dev/null)"
    if [ "$player_status" = "Playing" ]; then
      echo "$(${playerctl}/bin/playerctl metadata artist) - $(${playerctl}/bin/playerctl metadata title)"
    elif [ "$player_status" = "Paused" ]; then
      echo " $(${playerctl}/bin/playerctl metadata artist) - $(${playerctl}/bin/playerctl metadata title)"
    fi
  '';

  config = writeText "waybar-config" ''
    {
        "layer": "top", // Waybar at top layer
        "position": "bottom", // Waybar at the bottom of your screen
        "height": 25, // Waybar height
        // "width": 1280, // Waybar width
        // Choose the order of the modules
        "modules-left": ["sway/workspaces", "sway/mode", "custom/spotify"],
        "modules-center": ["sway/window"],
        "modules-right": ["idle_inhibitor", "pulseaudio", "network", "cpu", "memory", "backlight", "battery", "battery#bat2", "clock", "tray"],
        // Modules configuration
        // "sway/workspaces": {
        //     "disable-scroll": true,
        //     "all-outputs": true,
        //     "format": "{name}: {icon}",
        //     "format-icons": {
        //         "1": "",
        //         "2": "",
        //         "3": "",
        //         "4": "",
        //         "5": "",
        //         "urgent": "",
        //         "focused": "",
        //         "default": ""
        //     }
        // },
        "sway/mode": {
            "format": "<span style=\"italic\">{}</span>"
        },
        "idle_inhibitor": {
            "format": "{icon}",
            "format-icons": {
                "activated": "",
                "deactivated": ""
            }
        },
        "tray": {
            // "icon-size": 21,
            "spacing": 10
        },
        "clock": {
            "tooltip-format": "{:%Y-%m-%d | %H:%M}",
            "format-alt": "{:%Y-%m-%d}"
        },
        "cpu": {
            "format": "{usage}% "
        },
        "memory": {
            "format": "{}% "
        },
        "backlight": {
            // "device": "acpi_video1",
            "format": "{percent}% {icon}",
            "format-icons": ["", ""]
        },
        "battery": {
            "states": {
                // "good": 95,
                "warning": 30,
                "critical": 15
            },
            "format": "{capacity}% {icon}",
            // "format-good": "", // An empty format will hide the module
            // "format-full": "",
            "format-icons": ["", "", "", "", ""]
        },
        "battery#bat2": {
            "bat": "BAT2"
        },
        "network": {
            // "interface": "wlp2s0", // (Optional) To force the use of this interface
            "format-wifi": "{essid} ({signalStrength}%) ",
            "format-ethernet": "{ifname}: {ipaddr}/{cidr} ",
            "format-disconnected": "Disconnected ⚠"
        },
        "pulseaudio": {
            //"scroll-step": 1,
            "format": "{volume}% {icon}",
            "format-bluetooth": "{volume}% {icon}",
            "format-muted": "",
            "format-icons": {
                "headphones": "",
                "handsfree": "",
                "headset": "",
                "phone": "",
                "portable": "",
                "car": "",
                "default": ["", ""]
            },
            "on-click": "pavucontrol"
        },
        "custom/spotify": {
            "format": " {}",
            "max-length": 40,
            "exec": "${playerstatus}/bin/playerstatus 2> /dev/null"
        }
    }
  '';

in


  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/waybar"; }}
      ${libdot.copy { path = config; to = ".config/waybar/config";  }}
      ${libdot.copy { path = style; to = ".config/waybar/style.css";  }}
    '';
  }
