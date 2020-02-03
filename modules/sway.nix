{ pkgs, config, lib, options }:
with lib;
let
  cfg = config.programs.sway;

  sharedOptions = {
    fonts = mkOption {
      type = types.listOf types.str;
      default = ["monospace 8"];
      description = ''
        Font list used for window titles.
      '';
      example = [ "FontAwesome 10" "Terminus 10" ];
    };
  };

  startupModule = types.submodule {
    options = {
      command = mkOption {
        type = types.either types.str types.path;
        description = "Command that will be executed on startup.";
      };

      always = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to run command on each sway restart.";
      };

    };
  };

  barColorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  colorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      childBorder = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };

      indicator = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  barColorSingle = default: mkOption { inherit default; type = types.str; };
  barColorTriple = default: mkOption { inherit default; type = barColorSetModule; };
  barModule = types.submodule {
    options = {
      inherit (sharedOptions) fonts;
      mode = mkOption {
        type = types.enum [ "dock" "hide" "invisible" ];
        default = "dock";
        description = "Bar visibility mode.";
      };
      hiddenState = mkOption {
        type = types.enum [ "hide" "show" ];
        default = "hide";
        description = "The default bar mode when 'bar.mode' == 'hide'.";
      };
      position = mkOption {
        type = types.enum [ "top" "bottom" ];
        default = "bottom";
        description = "The edge of the screen i3bar should show up.";
      };
      statusCommand = mkOption {
        type = types.str;
        default = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config";
        description = "Command that will be used to get status lines.";
      };
      separatorSymbol = mkOption {
        type = types.str;
        default = "";
        description = "Specifies the separator symbol to separate blocks on the bar.";
      };
      height = mkOption {
        type = types.int;
        default = 18;
        description = "The height of the bar";
        apply = val: toString(val);
      };
      colors = mkOption {
        type = types.submodule {
          options = {
            background = barColorSingle "#000000";
            statusline = barColorSingle "#ffffff";
            separator = barColorSingle "#666666";

            focusedWorkspace = barColorTriple { border = "#4c7899"; background = "#285577"; text = "#ffffff"; };

            activeWorkspace = barColorTriple { border = "#333333"; background = "#5f676a"; text = "#ffffff"; };

            inactiveWorkspace = barColorTriple { border = "#333333"; background = "#222222"; text = "#888888"; };

            urgentWorkspace = barColorTriple { border = "#2f343a"; background = "#900000"; text = "#ffffff"; };

            bindingMode = barColorTriple { border = "#2f343a"; background = "#900000"; text = "#ffffff"; };
          };
        };
        default = {};
        description = ''
          Bar color settings. All color classes can be specified using submodules
          with 'border', 'background', 'text', fields and RGB color hex-codes as values.
        '';
      };

      #trayOutput = mkOption {
      #  type = types.str;
      #  default = "primary";
      #  description = "Where to output tray.";
      #};
    };

  };

  criteriaModule = types.attrsOf types.str;

  windowCommandModule = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "sway command to execute.";
        example = "border pixel 1";
      };

      criteria = mkOption {
        type = criteriaModule;
        description = "Criteria of the windows on which command should be executed.";
        example = { title = "x200: ~/work"; };
      };
    };
  };

  configModule = types.submodule {
    options = {
      inherit (sharedOptions) fonts;

      window = mkOption {
       type = types.submodule {
          options = {
            titlebar = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to show window titlebars.";
            };

            border = mkOption {
              type = types.int;
              default = 2;
              description = "Window border width.";
            };

            hideEdgeBorders = mkOption {
              type = types.enum [ "none" "vertical" "horizontal" "both" "smart" ];
              default = "none";
              description = "Hide window borders adjacent to the screen edges.";
            };

            popupDuringFullscreen = mkOption {
              type = types.enum [ "smart" "ignore" "leave_fullscreen" ];
              default = "smart";
              description = ''
                Determines what to do when a fullscreen view opens a dialog.
                If _smart_ (the default), the dialog will be displayed. If _ignore_, the
                dialog will not be rendered. If _leave_fullscreen_, the view will exit
                fullscreen mode and the dialog will be rendered.
              '';
            };

            commands = mkOption {
              type = types.listOf windowCommandModule;
              default = [];
              description = ''
                List of commands that should be executed on specific windows.
              '';
              example = [ { command = "border pixel 1"; criteria = { class = "XTerm"; }; } ];
            };

            noFocusCriteria = mkOption {
              type = types.listOf criteriaModule;
              default = [];
              description = ''
                List of commands that should be executed on specific windows.
              '';
              example = [ { class = "XTerm"; } ];
            };
          };
        };
        default = {};
        description = "Window titlebar and border settings.";
      };

      floating = mkOption {
        type = types.submodule {
          options = {
            titlebar = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to show floating window titlebars.";
            };

            border = mkOption {
              type = types.int;
              default = 2;
              description = "Floating windows border width.";
            };

            modifier = mkOption {
              type = types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
              default = cfg.settings.modifier;
              defaultText = "i3.config.modifier";
              description = "Modifier key that can be used to drag floating windows.";
              example = "Mod4";
            };

            criteria = mkOption {
              type = types.listOf criteriaModule;
              default = [];
              description = "List of criteria for windows that should be opened in a floating mode.";
              example = [ {"title" = "Steam - Update News";} {"class" = "Pavucontrol";} ];
            };
          };
        };
        default = {};
        description = "Floating window settings.";
      };

      focus = mkOption {
        type = types.submodule {
          options = {
            newWindow = mkOption {
              type = types.enum [ "smart" "urgent" "focus" "none" ];
              default = "smart";
              description = ''
                This option modifies focus behavior on new window activation.
              '';
              example = "none";
            };

            followMouse = mkOption {
              type = types.bool;
              default = true;
              description = "Whether focus should follow the mouse.";
            };

            forceWrapping = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to use focus wrapping in tabbed or stacked container.
              '';
            };

            mouseWarping = mkOption {
              type = types.enum [ "output" "container" "none" ];
              default = "none";
              description = ''
                Whether mouse cursor should be warped to the center of the window when switching focus
                to a window on a different output or in a different container.
              '';
            };
          };
        };
        default = {};
        description = "Focus related settings.";
      };

      assigns = mkOption {
        type = types.attrsOf (types.listOf criteriaModule);
        default = {};
        description = ''
          An attribute set that assigns applications to workspaces based
          on criteria.
        '';
        example = literalExample ''
          {
            "1: web" = [{ class = "^Firefox$"; }];
            "0: extra" = [{ class = "^Firefox$"; window_role = "About"; }];
          }
        '';
      };

      modifier = mkOption {
        type = types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
        default = "Mod1";
        description = "Modifier key that is used for all default keybindings.";
        example = "Mod4";
      };

      workspaceLayout = mkOption {
        type = types.enum [ "default" "stacked" "tabbed" ];
        default = "default";
        example = "tabbed";
        description = ''
          The mode in which new containers on workspace level will
          start.
        '';
      };

      workspaceAutoBackAndForth = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether a second press on the workspace number takes you
          back to where you came from.
        '';
      };

      keybindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = mapAttrs (n: mkOptionDefault) {
          "${cfg.settings.modifier}+Return" = "exec alacritty";
          "${cfg.settings.modifier}+Shift+q" = "kill";
          "${cfg.settings.modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";

          "${cfg.settings.modifier}+Left" = "focus left";
          "${cfg.settings.modifier}+Down" = "focus down";
          "${cfg.settings.modifier}+Up" = "focus up";
          "${cfg.settings.modifier}+Right" = "focus right";

          "${cfg.settings.modifier}+Shift+Left" = "move left";
          "${cfg.settings.modifier}+Shift+Down" = "move down";
          "${cfg.settings.modifier}+Shift+Up" = "move up";
          "${cfg.settings.modifier}+Shift+Right" = "move right";

          "${cfg.settings.modifier}+h" = "split h";
          "${cfg.settings.modifier}+v" = "split v";
          "${cfg.settings.modifier}+f" = "fullscreen toggle";

          "${cfg.settings.modifier}+s" = "layout stacking";
          "${cfg.settings.modifier}+w" = "layout tabbed";
          "${cfg.settings.modifier}+e" = "layout toggle split";

          "${cfg.settings.modifier}+Shift+space" = "floating toggle";
          "${cfg.settings.modifier}+space" = "focus mode_toggle";

          "${cfg.settings.modifier}+1" = "workspace number 1";
          "${cfg.settings.modifier}+2" = "workspace number 2";
          "${cfg.settings.modifier}+3" = "workspace number 3";
          "${cfg.settings.modifier}+4" = "workspace number 4";
          "${cfg.settings.modifier}+5" = "workspace number 5";
          "${cfg.settings.modifier}+6" = "workspace number 6";
          "${cfg.settings.modifier}+7" = "workspace number 7";
          "${cfg.settings.modifier}+8" = "workspace number 8";
          "${cfg.settings.modifier}+9" = "workspace number 9";

          "${cfg.settings.modifier}+Shift+1" = "move container to workspace number 1";
          "${cfg.settings.modifier}+Shift+2" = "move container to workspace number 2";
          "${cfg.settings.modifier}+Shift+3" = "move container to workspace number 3";
          "${cfg.settings.modifier}+Shift+4" = "move container to workspace number 4";
          "${cfg.settings.modifier}+Shift+5" = "move container to workspace number 5";
          "${cfg.settings.modifier}+Shift+6" = "move container to workspace number 6";
          "${cfg.settings.modifier}+Shift+7" = "move container to workspace number 7";
          "${cfg.settings.modifier}+Shift+8" = "move container to workspace number 8";
          "${cfg.settings.modifier}+Shift+9" = "move container to workspace number 9";

          "${cfg.settings.modifier}+Shift+c" = "reload";
          "${cfg.settings.modifier}+Shift+r" = "restart";
          "${cfg.settings.modifier}+Shift+e" = "exec swaynag -t warning -m 'Do you want to exit sway?' -b 'Yes' 'swaymsg exit'";

          "${cfg.settings.modifier}+r" = "mode resize";
        };
        defaultText = "Default sway keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          Consider to use <code>lib.mkOptionDefault</code> function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = literalExample ''
          let
            modifier = programs.sway.config.modifier;
          in

          lib.mkOptionDefault {
            "''${modifier}+Return" = "exec alacritty";
            "''${modifier}+Shift+q" = "kill";
            "''${modifier}+d" = "exec \${pkgs.dmenu}/bin/dmenu_run";
          }
        '';
      };

      keycodebindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = {};
        description = ''
          An attribute set that assigns keypress to an action using key code.
        '';
        example = { "214" = "exec --no-startup-id /bin/script.sh"; };
      };


      input = mkOption {
        type = types.attrsOf (types.attrsOf (types.either types.str types.bool));
        default = {};
        example = {
          "*" = {
            xkb_variant = "dvorak";
          };
        };
        description = ''
          An attribute set that defines input modules. See man sway_input for options.
        '';
      };

      output = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {};
        example = {
          "HDMI-A-2" = {
            bg = "~/path/to/background.png";
          };
        };
        description = ''
          An attribute set that defines output modules. See man sway_output for options.
        '';
      };

      colors = mkOption {
        type = types.submodule {
          options = {
            focused = mkOption {
              type = colorSetModule;
              default = {
                border = "#4c7899"; background = "#285577"; text = "#ffffff";
                indicator = "#2e9ef4"; childBorder = "#285577";
              };
              description = "A window which currently has the focus.";
            };

            focusedInactive = mkOption {
              type = colorSetModule;
              default = {
                border = "#333333"; background = "#5f676a"; text = "#ffffff";
                indicator = "#484e50"; childBorder = "#5f676a";
              };
              description = ''
                A window which is the focused one of its container,
                but it does not have the focus at the moment.
              '';
            };

            unfocused = mkOption {
              type = colorSetModule;
              default = {
                border = "#333333"; background = "#222222"; text = "#888888";
                indicator = "#292d2e"; childBorder = "#222222";
              };
              description = "A window which is not focused.";
            };

            urgent = mkOption {
              type = colorSetModule;
              default = {
                border = "#2f343a"; background = "#900000"; text = "#ffffff";
                indicator = "#900000"; childBorder = "#900000";
              };
              description = "A window which has its urgency hint activated.";
            };
          };
        };
        default = {};
        description = ''
          Color settings. All color classes can be specified using submodules
          with 'border', 'background', 'text', 'indicator' and 'childBorder' fields
          and RGB color hex-codes as values. See default values for the reference.
        '';
      };

      modes = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          resize = {
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'sway.extraConfig'.
        '';
      };

      bars = mkOption {
        type = types.listOf barModule;
        default = [{}];
        description = ''
          sway bars settings blocks. Set to empty list to remove bars completely.
        '';
      };

      startup = mkOption {
        type = types.listOf startupModule;
        default = [];
        description = ''
          Commands that should be executed at startup.

        '';
        example = literalExample ''
          [
            { command = "systemctl --user restart polybar"; always = true; notification = false; }
            { command = "dropbox start"; notification = false; }
            { command = "firefox"; workspace = "1: web"; }
          ];
        '';
      };

      gaps = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            inner = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Inner gaps value.";
              example = 12;
            };

            outer = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Outer gaps value.";
              example = 5;
            };

            smartGaps = mkOption {
              type = types.bool;
              default = false;
              description = ''
                This option controls whether to disable all gaps (outer and inner)
                on workspace with a single container.
              '';
              example = true;
            };

            smartBorders = mkOption {
              type = types.enum [ "on" "off" "no_gaps" ];
              default = "off";
              description = ''
                This option controls whether to disable container borders on
                workspace with a single container.
              '';
            };
          };
        });
        default = null;
      };
    };
  };

  keybindingsStr = keybindings: concatStringsSep "\n" (
    mapAttrsToList (keycomb: action: optionalString (action != null) "bindsym ${keycomb} ${action}") keybindings
  );

  keycodebindingsStr = keycodebindings: concatStringsSep "\n" (
    mapAttrsToList (keycomb: action: optionalString (action != null) "bindcode ${keycomb} ${action}") keycodebindings
  );

  colorSetStr = c: concatStringsSep " " [ c.border c.background c.text c.indicator c.childBorder ];
  barColorSetStr = c: concatStringsSep " " [ c.border c.background c.text ];

  criteriaStr = criteria: "[${concatStringsSep " " (mapAttrsToList (k: v: ''${k}="${v}"'') criteria)}]";

  modeStr = name: keybindings: ''
    mode "${name}" {
    ${keybindingsStr keybindings}
    }
  '';

  assignStr = workspace: criteria: concatStringsSep "\n" (
    map (c: "assign ${criteriaStr c} ${workspace}") criteria
  );

  barStr = {
    id ? null, fonts, height, mode, hiddenState, position,
    statusCommand, colors, separatorSymbol, ...
  }: ''
    bar {
      font pango:${concatStringsSep ", " fonts}
      mode ${mode}
      height ${height}
      hidden_state ${hiddenState}
      position ${position}
      status_command ${statusCommand}
      separator_symbol "${separatorSymbol}"
      colors {
        background ${colors.background}
        statusline ${colors.statusline}
        separator ${colors.separator}
        focused_workspace ${barColorSetStr colors.focusedWorkspace}
        active_workspace ${barColorSetStr colors.activeWorkspace}
        inactive_workspace ${barColorSetStr colors.inactiveWorkspace}
        urgent_workspace ${barColorSetStr colors.urgentWorkspace}
        binding_mode ${barColorSetStr colors.bindingMode}
      }
    }
  '';

  gapsStr = with cfg.config.gaps; ''
    ${optionalString (inner != null) "gaps inner ${toString inner}"}
    ${optionalString (outer != null) "gaps outer ${toString outer}"}
    ${optionalString smartGaps "smart_gaps on"}
    ${optionalString (smartBorders != "off") "smart_borders ${smartBorders}"}
  '';

  floatingCriteriaStr = criteria: "for_window ${criteriaStr criteria} floating enable";
  windowCommandsStr = { command, criteria, ... }: "for_window ${criteriaStr criteria} ${command}";

  noFocusCriteriaStr = criteria: "no_focus ${criteriaStr criteria}";

  startupEntryStr = { command, always, ... }: ''
    ${if always then "exec_always" else "exec"} --no-startup-id ${command}
  '';

  inputStr = name: attrs:
    let
      toVal = v:
        if isString v then
          if v == "" then ''""'' else v
        else if isBool v then
          if v then "enabled" else "disabled"
        else toString v;
    in
    ''
    input "${name}" {
    ${concatStringsSep "\n" (mapAttrsToList (name: value: "${name} ${toVal value}") attrs)}
    }
  '';

  outputStr = name: attrs: ''
    output "${name}" {
    ${concatStringsSep "\n" (mapAttrsToList (name: value: "${name} ${value}") attrs)}
    }
  '';

  configFile = pkgs.writeText "sway.config" ((if cfg.settings != null then with cfg.settings; ''
    font pango:${concatStringsSep ", " fonts}

    floating_modifier ${floating.modifier}
    default_border ${if window.titlebar then "normal" else "pixel"} ${toString window.border}
    default_floating_border ${if floating.titlebar then "normal" else "pixel"} ${toString floating.border}
    hide_edge_borders ${window.hideEdgeBorders}
    popup_during_fullscreen ${window.popupDuringFullscreen}
    focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
    focus_follows_mouse ${if focus.followMouse then "yes" else "no"}
    focus_on_window_activation ${focus.newWindow}
    mouse_warping ${focus.mouseWarping}
    workspace_layout ${workspaceLayout}
    workspace_auto_back_and_forth ${if workspaceAutoBackAndForth then "yes" else "no"}

    client.focused ${colorSetStr colors.focused}
    client.focused_inactive ${colorSetStr colors.focusedInactive}
    client.unfocused ${colorSetStr colors.unfocused}
    client.urgent ${colorSetStr colors.urgent}

    ${keybindingsStr keybindings}
    ${keycodebindingsStr keycodebindings}
    ${concatStringsSep "\n" (mapAttrsToList inputStr input)}
    ${concatStringsSep "\n" (mapAttrsToList outputStr output)}
    ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
    ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
    ${concatStringsSep "\n" (map barStr bars)}
    ${optionalString (gaps != null) gapsStr}
    ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
    ${concatStringsSep "\n" (map windowCommandsStr window.commands)}
    ${concatStringsSep "\n" (map noFocusCriteriaStr window.noFocusCriteria)}
    ${concatStringsSep "\n" (map startupEntryStr startup)}
  '' else "") + "\n" + cfg.extraConfig);
in
{
  options = {
    programs.sway = {
      enable = mkEnableOption "sway";
      source = mkOption {
        type = types.path;
        default = configFile;
      };
      settings = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "sway configuration";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "extra config";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.settings != null) {
      xdg.configFile."sway/config" = {
        source = configFile;
      };
    })
  ]);
}