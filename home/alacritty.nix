{ pkgs, config, lib, options }:

rec {
  programs.alacritty = {
     enable = true;
     settings = rec {
       window = {
         dimensions.columns = 80;
         dimensions.lines = 24;
         padding.x = 2;
         padding.y = 2;
       };
       tabspaces = 8;
       draw_bold_text_with_bright_colors = true;
       scrolling = {
         history = 20000;
         multiplier = 20;
       };
       font = {
         normal.family = "JetBrains Mono";
         size = 14.0;
         offset.x = 0;
         offset.y = 0;
         glyph_offset.x = 0;
         glyph_offset.y = 0;
         use_thin_strokes = true; ## osx only but won't have a negative effect
       };
       background_opacity = 0.95;
       colors = {
         primary.background = "0x00374e"; ## special - not part of theme
         primary.foreground = "0xD8DEE9";

         cursor.text = "0x2E3440";
         cursor.cursor = "0xD8DEE9";

         normal.black = "0x3B4252";
         normal.red = "0xBF616A";
         normal.green = "0xA3BE8C";
         normal.yellow = "0xEBCB8B";
         normal.blue = "0x81A1C1";
         normal.magenta = "0xB48EAD";
         normal.cyan = "0x88C0D0";
         normal.white = "0xE5E9F0";

         bright.black = "0x4C566A";
         bright.red = "0xBF616A";
         bright.green = "0xA3BE8C";
         bright.yellow = "0xEBCB8B";
         bright.blue = "0x81A1C1";
         bright.magenta = "0xB48EAD";
         bright.cyan = "0x8FBCBB";
         bright.white = "0xECEFF4";
       };
       visual_bell.animation = "EaseOutExpo";
       visual_bell.duration = 0;

       key_bindings = [
         { key = "V";        mods = "Control|Shift";                      action = "Paste";                                 }
         { key = "C";        mods = "Control|Shift";                      action = "Copy";                                  }
         { key = "Q";        mods = "Command";                            action = "Quit";                                  }
         { key = "W";        mods = "Command";                            action = "Quit";                                  }
         { key = "Insert";   mods = "Shift";                              action = "PasteSelection";                        }
         { key = "Home";                             chars = "\\x1bOH";                                mode = "AppCursor";  }
         { key = "Home";                             chars = "\\x1b[1~";                               mode = "~AppCursor"; }
         { key = "End";                              chars = "\\x1bOF";                                mode = "AppCursor";  }
         { key = "End";                              chars = "\\x1b[4~";                               mode = "~AppCursor"; }
         { key = "PageUp";   mods = "Shift";         chars = "\\x1b[5;2~";                                                  }
         { key = "PageUp";   mods = "Control";       chars = "\\x1b[5;5~";                                                  }
         { key = "PageUp";                           chars = "\\x1b[5~";                                                    }
         { key = "PageDown"; mods = "Shift";         chars = "\\x1b[6;2~";                                                  }
         { key = "PageDown"; mods = "Control";       chars = "\\x1b[6;5~";                                                  }
         { key = "PageDown";                         chars = "\\x1b[6~";                                                    }
         { key = "Left";     mods = "Shift";         chars = "\\x1b[1;2D";                                                  }
         { key = "Left";     mods = "Control";       chars = "\\x1b[1;5D";                                                  }
         { key = "Left";     mods = "Alt";           chars = "\\x1b[1;3D";                                                  }
         { key = "Left";                             chars = "\\x1b[D";                                mode = "~AppCursor"; }
         { key = "Left";                             chars = "\\x1bOD";                                mode = "AppCursor";  }
         { key = "Right";    mods = "Shift";         chars = "\\x1b[1;2C";                                                  }
         { key = "Right";    mods = "Control";       chars = "\\x1b[1;5C";                                                  }
         { key = "Right";    mods = "Alt";           chars = "\\x1b[1;3C";                                                  }
         { key = "Right";                            chars = "\\x1b[C";                                mode = "~AppCursor"; }
         { key = "Right";                            chars = "\\x1bOC";                                mode = "AppCursor";  }
         { key = "Up";       mods = "Shift";         chars = "\\x1b[1;2A";                                                  }
         { key = "Up";       mods = "Control";       chars = "\\x1b[1;5A";                                                  }
         { key = "Up";       mods = "Alt";           chars = "\\x1b[1;3A";                                                  }
         { key = "Up";                               chars = "\\x1b[A";                                mode = "~AppCursor"; }
         { key = "Up";                               chars = "\\x1bOA";                                mode = "AppCursor";  }
         { key = "Down";     mods = "Shift";         chars = "\\x1b[1;2B";                                                  }
         { key = "Down";     mods = "Control";       chars = "\\x1b[1;5B";                                                  }
         { key = "Down";     mods = "Alt";           chars = "\\x1b[1;3B";                                                  }
         { key = "Down";                             chars = "\\x1b[B";                                mode = "~AppCursor"; }
         { key = "Down";                             chars = "\\x1bOB";                                mode = "AppCursor";  }
         { key = "Tab";      mods = "Shift";         chars = "\\x1b[Z";                                                     }
         { key = "F1";                               chars = "\\x1bOP";                                                     }
         { key = "F2";                               chars = "\\x1bOQ";                                                     }
         { key = "F3";                               chars = "\\x1bOR";                                                     }
         { key = "F4";                               chars = "\\x1bOS";                                                     }
         { key = "F5";                               chars = "\\x1b[15~";                                                   }
         { key = "F6";                               chars = "\\x1b[17~";                                                   }
         { key = "F7";                               chars = "\\x1b[18~";                                                   }
         { key = "F8";                               chars = "\\x1b[19~";                                                   }
         { key = "F9";                               chars = "\\x1b[20~";                                                   }
         { key = "F10";                              chars = "\\x1b[21~";                                                   }
         { key = "F11";                              chars = "\\x1b[23~";                                                   }
         { key = "F12";                              chars = "\\x1b[24~";                                                   }
         { key = "Back";                             chars = "\\x7f";                                                       }
         { key = "Back";     mods = "Alt";           chars = "\\x1b\x7f";                                                   }
         { key = "Insert";                           chars = "\\x1b[2~";                                                    }
         { key = "Delete";                           chars = "\\x1b[3~";                                                    }
       ];

       mouse_bindings = [
         { mouse = "Middle"; action = "PasteSelection"; }
       ];

       mouse.double_click.threshold = 300;
       mouse.triple_click.threshold = 300;
       mouse.hide_cursor_when_typing = true;

       selection.semantic_escape_chars = ",│`|:\"' ()[]{}<>";
     };
  };

  xdg.configFile."alacritty/alacritty-launcher.yml" = {
    text =
      lib.replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON (programs.alacritty.settings // { font.size = 28.0; font.normal.family = "Roboto Mono"; }));
  };

}