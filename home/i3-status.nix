{ pkgs, config, lib, options }:

let
  check-nixos-version = pkgs.writeStrictShellScriptBin "check-nixos-version" ''
    CURRENT=$(${pkgs.curl}/bin/curl -sS https://howoldis.herokuapp.com/api/channels | \
              ${pkgs.jq}/bin/jq -r '.[] | select(.name == "nixos-unstable") | "\(.link) \(.time)"')
    AGE_SECS=$(echo "$CURRENT" | awk '{print $2}')
    AGE_DAYS="$(echo "$AGE_SECS / 60 / 60 / 24" | ${pkgs.bc}/bin/bc)"
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

in

{
  programs.i3status-rust = {
     enable = true;
     settings = {
       block = [

         {
           block = "custom";
           interval = 600;
           command = "${check-nixos-version}/bin/check-nixos-version";
         }

         {
           block = "cpu";
           interval = 1;
         }

         {
           block = "backlight";
         }

         {
           block = "battery";
           interval = 10;
           format = "{percentage}% {time}";
         }

         {
           block = "net";
           device = "wlan0";
           ssid = true;
           signal_strength = true;
           ip = false;
           speed_up = true;
           graph_up = false;
           interval = 5;
         }

         { block = "sound"; }

         #headphones = {
         #  block = "bluetooth";
         #  opts.mac = "04:52:C7:5F:CC:B6";
         #};

         #mouse = {
         #  block = "bluetooth";
         #  opts.mac = "D5:17:1A:80:22:AA";
         #};

         {
           block = "time";
           interval = 1;
           format = "%b-%d %H:%M:%S";
         }

       ];
     };
     #blocks = {
     #  custom = {
     #    opts = {
     #      interval = 600;
     #      command = "${check-nixos-version}/bin/check-nixos-version";
     #    };
     #  };
     #  cpu = {
     #    opts.interval = 1;
     #  };
     #  backlight = {
     #  };
     #  battery = {
     #    opts = {
     #      interval = 10;
     #      format = "{percentage}% {time}";
     #    };
     #  };
     #  net = {
     #    opts = {
     #      device = "wlan0";
     #      ssid = true;
     #      signal_strength = true;
     #      ip = false;
     #      speed_up = true;
     #      graph_up = false;
     #      interval = 5;
     #    };
     #  };

     #  sound = {
     #  };

     #  #headphones = {
     #  #  block = "bluetooth";
     #  #  opts.mac = "04:52:C7:5F:CC:B6";
     #  #};

     #  #mouse = {
     #  #  block = "bluetooth";
     #  #  opts.mac = "D5:17:1A:80:22:AA";
     #  #};

     #  time = {
     #    opts = {
     #      interval = 1;
     #      format = "%b-%d %H:%M:%S";
     #    };
     #  };
     #};
  };
}