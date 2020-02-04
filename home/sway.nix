{ pkgs, config, lib, options }:

let

  #import-gsettings = pkgs.writeShellScriptBin "import-gsettings" ''
  #  # usage: import-gsettings <gsettings key>:<settings.ini key> <gsettings key>:<settings.ini key> ...
  #  PATH=${pkgs.gnused}/bin:${pkgs.glib}/bin:$PATH
  #  expression=""
  #  for pair in "$@"; do
  #      IFS=:; set -- $pair
  #      expressions="$expressions -e 's:^$2=(.*)$:gsettings set org.gnome.desktop.interface $1 \1:e'"
  #  done
  #  IFS=
  #  eval exec sed -E $expressions "''${XDG_CONFIG_HOME:-$HOME/.config}"/gtk-3.0/settings.ini >/dev/null
  #'';

  swaylockBackground = "~/Pictures/lockscreen.jpg";
  swaylockArgs = "-e -i ${swaylockBackground} -K -s fill --font Roboto --inside-color 00000066 --inside-clear-color 00660099 --inside-ver-color 00006699 --inside-wrong-color 66000099 --key-hl-color FFFFFF99 --ring-color GGGGGGBB --ring-wrong-color FF6666BB --ring-ver-color 6666FFBB --text-color FFFFFFFF --text-clear-color FFFFFFFF --text-wrong-color FFFFFFFF --text-ver-color FFFFFFFF";
  swaylockTimeout = "300";
  swaylockSleepTimeout = "310";
  swayidleCommand = lib.concatStringsSep " " [
    "swayidle -w"
    "timeout ${swaylockTimeout}"
    "'swaylock -f ${swaylockArgs}'"
    "timeout ${swaylockSleepTimeout}"
    "'swaymsg \"output * dpms off\"'"
    "resume 'swaymsg \"output * dpms on\"'"
    "before-sleep 'swaylock -f ${swaylockArgs}'"
  ];

  toggle-keyboard-layouts = pkgs.writeStrictShellScriptBin "toggle-keyboard-layouts" ''
    export PATH=${pkgs.jq}/bin''${PATH:+:}$PATH
    current_layout="$(swaymsg -t get_inputs -r | jq -r "[.[] | select(.xkb_active_layout_name != null)][0].xkb_active_layout_name")"
    if [ "$current_layout" = "English (US)" ]; then
      swaymsg 'input "*" xkb_layout se'
    else
      swaymsg 'input "*" xkb_layout us'
    fi
  '';

  random-background = pkgs.writeStrictShellScriptBin "random-background" ''
    if [ ! -d "$HOME"/Pictures/backgrounds ] ||
       [ "$(${pkgs.findutils}/bin/find "$HOME"/Pictures/backgrounds/ -type f | wc -l)" = "0" ]; then
       echo "$HOME"/Pictures/default-background.png
       exit
    fi
    ${pkgs.findutils}/bin/find "$HOME/Pictures/backgrounds" -type f | \
         ${pkgs.coreutils}/bin/sort -R | ${pkgs.coreutils}/bin/tail -1
  '';

  random-picsum-background = pkgs.writeStrictShellScriptBin "random-picsum-background" ''
    category=''${1:-nature}
    ${pkgs.wget}/bin/wget -O /tmp/wallpaper.jpg 'https://source.unsplash.com/random/3200x1800/?'"$category" 2>/dev/null
    if [ -e "$HOME"/Pictures/wallpaper.jpg ]; then
      mv "$HOME"/Pictures/wallpaper.jpg "$HOME"/Pictures/previous-wallpaper.jpg
    fi
    mv /tmp/wallpaper.jpg "$HOME"/Pictures/wallpaper.jpg
    echo "$HOME"/Pictures/wallpaper.jpg
  '';

  sway-background = pkgs.writeStrictShellScriptBin "sway-background" ''
    category=''${1:-nature}
    BG=$(${random-picsum-background}/bin/random-picsum-background "$category")
    exec swaymsg "output * bg '$BG' fill"
  '';

  rotating-background = pkgs.writeStrictShellScriptBin "rotating-background" ''
    category=''${1:-nature}
    while true; do
      ${sway-background}/bin/sway-background "$category"
      sleep 600
    done
  '';

in

{
  programs.sway = {
     enable = true;
     settings = rec {
       fonts = [ "Roboto" "Font Awesome 5 Free" "Font Awesome 5 Brands" "Roboto" "Arial" "sans-serif" "Bold 10" ];
       modifier = "Mod4";

       output = {
         "Unknown ASUS PB27U 0x0000C167" = {
           scale = "1.5";
         };
         "Unknown Q2790 GQMJ4HA000414" = {
           scale = "1.0";
         };
         "*" = {
           bg = "~/Pictures/background.jpg fill";
         };
       };

       focus = {
         followMouse = true;
         newWindow = "smart";
       };

       workspaceAutoBackAndForth = true;

       window = let
         command = "floating enable, resize set width 100ppt height 120ppt";
         floatCommand = "floating enable";
       in
         {
         titlebar = false;
         border = 0;
         hideEdgeBorders = "smart";
         popupDuringFullscreen = "smart";
         commands = [
           { inherit command; criteria = { class = "sk-window"; }; }
           { inherit command; criteria = { title = "sk-window"; }; }
           { inherit command; criteria = { app_id = "sk-window"; }; }
           { command = floatCommand; criteria = { class = "input-window"; }; }
           { command = floatCommand; criteria = { class = "gcr-prompter"; }; }
         ];
         noFocusCriteria = [
           { window_role = "browser"; }
         ];
       };

       floating = {
         titlebar = false;
         border = 0;
       };

       input = {
          "*" = {
             xkb_layout = "us";
             xkb_model = "pc105";
             xkb_options = "ctrl:nocaps,lv3:lalt_switch,compose:ralt,lv3:ralt_alt";
             xkb_variant = "";
          };
         "1739:30383:DLL075B:01_06CB:76AF_Touchpad" = {
            dwt = true;
            natural_scroll = true;
            tap = true;
         };
         "1739:30383:DELL07E6:00_06CB:76AF_Touchpad" = {
            dwt = true;
            natural_scroll = true;
            tap = true;
         };
       };

       colors = rec {
         focused = {
           border = "#5E81AC"; background = "#5E81AC"; text = "#ECEFF4";
           indicator = "#5E81AC"; childBorder = "#5E81AC";
         };

         focusedInactive = {
           border = "#2E3440"; background = "#2E3440"; text = "#8FBCBB";
           indicator = "#2E3440"; childBorder = "#2E3440";
         };

         unfocused = focusedInactive;

         urgent = {
           border = "#BF616A"; background = "#BF616A"; text = "#E5E9F0";
           indicator = "#BF616A"; childBorder = "#BF616A";
         };

       };

       modes = {
         resize = {
           Left = "resize shrink width 10 px or 10 ppt";
           Right = "resize grow width 10 px or 10 ppt";
           Up = "resize shrink height 10 px or 10 ppt";
           Down = "resize grow height 10 px or 10 ppt";
           Return = "mode default";
           Escape = "mode default";
         };

         "disabled keybindings" = {
           Escape = "mode default";
         };

         "(p)oweroff, (s)uspend, (h)ibernate, (r)eboot, (l)ogout" = {
           p = "exec swaymsg 'mode default' && systemctl poweroff";
           s = "exec swaymsg 'mode default' && systemctl suspend-then-hibernate";
           h = "exec swaymsg 'mode default' && systemctl hibernate";
           r = "exec swaymsg 'mode default' && systemctl reboot";
           l = "exec swaymsg 'mode default' && swaymsg exit";
           Return = "mode default";
           Escape = "mode default";
         };

       };

       keybindings = lib.mkOptionDefault {
         "${modifier}+Escape"      = ''mode "(p)oweroff, (s)uspend, (h)ibernate, (r)eboot, (l)ogout"'';
         "${modifier}+x"           = ''mode "disabled keybindings"'';
         "${modifier}+r"           = ''mode "resize"'';

         "${modifier}+t"           = ''exec ${pkgs.spotify-play-track}/bin/spotify-play-track'';
         "${modifier}+p"           = ''exec ${pkgs.spotify-play-playlist}/bin/spotify-play-playlist'';
         "${modifier}+Shift+n"     = ''exec ${pkgs.spotify-cmd}/bin/spotify-cmd next'';
         "${modifier}+Shift+p"     = ''exec ${pkgs.spotify-cmd}/bin/spotify-cmd prev'';
         "${modifier}+Shift+m"     = ''exec ${pkgs.spotify-cmd}/bin/spotify-cmd pause'';

         "${modifier}+Control+k"   = ''exec ${toggle-keyboard-layouts}/bin/toggle-keyboard-layouts'';

         "${modifier}+Control+l"   = ''exec swaylock -f ${swaylockArgs}'';


         "${modifier}+i"           = ''exec swaymsg inhibit_idle open'';
         "${modifier}+Shift+i"     = ''exec swaymsg inhibit_idle none'';

         "${modifier}+Return"      = ''exec _USE_NAME=>_ ${pkgs.launch}/bin/launch terminal'';
         "${modifier}+d"           = ''exec sk-window sk-run'';

         "${modifier}+minus"       = ''exec sk-window sk-passmenu'';
         "${modifier}+Shift+minus" = ''exec passonly=y sk-window sk-passmenu'';

         "${modifier}+b"           = ''exec sway-background'';

         "${modifier}+Shift+e"     = ''exec _USE_NAME=  launch alacritty -t edit -e edi'';

         "${modifier}+Shift+b"     = ''exec _USE_NAME=  launch browse'';

         "${modifier}+m"           = ''move workspace to output right'';
         "${modifier}+Shift+q"     = ''kill'';

         "XF86MonBrightnessUp"     = ''exec light -As "sysfs/backlight/intel_backlight" 5'';
         "XF86MonBrightnessDown"   = ''exec light -Us "sysfs/backlight/intel_backlight" 5'';

         "${modifier}+q"           = ''layout stacking'';
         "${modifier}+o"           = ''move absolute position center'';
         "${modifier}+a"           = ''focus parent'';
       };

       startup = [
         {
           command = "${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources";
         }
         {
           command = "${pkgs.persway}/bin/persway";
         }
         {
           command = "echo UPDATESTARTUPTTY | ${pkgs.gnupg}/bin/gpg-connect-agent";
         }
         #{
         #  command = "${import-gsettings}/bin/import-gsettings gtk-theme:gtk-theme-name icon-theme:gtk-icon-theme-name cursor-theme:gtk-cursor-theme-name";
         #  always = true;
         #}
         {
           command = "${pkgs.gnome3.gnome_settings_daemon}/libexec/gsd-xsettings";
         }

         {
           command = "${rotating-background}/bin/rotating-background art";
         }

         {
           command = swayidleCommand;
         }
       ];

       bars = [
         {
           inherit fonts;
           height = 25;
           colors = {
             background = "#2E3440AA";
             statusline = "#88C0D0";
             separator = "#3B4252";

             focusedWorkspace = {
               border = "#88C0D0";
               background = "#88C0D0";
               text = "#2E3440";
             };

             activeWorkspace = {
               border = "#4C566ADD";
               background = "#4C566ADD";
               text = "#D8DEE9";
             };

             inactiveWorkspace = {
               border = "#3B4252DD";
               background = "#3B4252DD";
               text = "#E5E9F0";
             };

             urgentWorkspace = {
               border = "#B48EAD";
               background = "#B48EAD";
               text = "#ECEFF4";
             };

             bindingMode = {
               border = "#BF616A";
               background = "#BF616A";
               text = "#E5E9F0";
             };
           };
         }
       ];
     };
  };
}