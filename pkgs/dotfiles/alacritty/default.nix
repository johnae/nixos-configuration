{stdenv, libdot, writeText, settings, ...}:

with settings.alacritty;

let

  defaultConfig = writeText "alacritty-config" ''
    # Configuration for Alacritty, the GPU enhanced terminal emulator

    # Any items in the `env` entry below will be added as
    # environment variables. Some entries may override variables
    # set by alacritty it self.
    env:
      # TERM env customization.
      #
      # If this property is not set, alacritty will set it to xterm-256color.
      #
      # Note that some xterm terminfo databases don't declare support for italics.
      # You can verify this by checking for the presence of `smso` and `sitm` in
      # `infocmp xterm-256color`.
      TERM: xterm-256color

    window:
      # Window dimensions in character columns and lines
      # (changes require restart)

      dimensions:
        columns: 80
        lines: 24

      # Adds this many blank pixels of padding around the window
      # Units are physical pixels; this is not DPI aware.
      # (change requires restart)
      padding:
        x: 2
        y: 2

    # Display tabs using this many cells (changes require restart)
    tabspaces: 8

    # When true, bold text is drawn using the bright variant of colors.
    draw_bold_text_with_bright_colors: true

    scrolling:
      history: 20000
      multiplier: 20
      auto_scroll: false

    # Font configuration (changes require restart)
    font:
      # The normal (roman) font face to use.
      normal:
        family: ${font}
        # family: monospace # should be "Menlo" or something on macOS.
        # Style can be specified to pick a specific face.
        # style: Regular

      # Point size of the font
      size: ${fontSize}

      # Offset is the extra space around each character. offset.y can be thought of
      # as modifying the linespacing, and offset.x as modifying the letter spacing.
      offset:
        x: 0
        y: 0

      # Glyph offset determines the locations of the glyphs within their cells with
      # the default being at the bottom. Increase the x offset to move the glyph to
      # the right, increase the y offset to move the glyph upward.
      glyph_offset:
        x: 0
        y: 0

      # OS X only: use thin stroke font rendering. Thin strokes are suitable
      # for retina displays, but for non-retina you probably want this set to
      # false.
      use_thin_strokes: true

    # Should display the render timer
    debug.render_timer: false

    background_opacity: ${backgroundOpacity}

    ${colors}

    # Visual Bell
    #
    # Any time the BEL code is received, Alacritty "rings" the visual bell. Once
    # rung, the terminal background will be set to white and transition back to the
    # default background color. You can control the rate of this transition by
    # setting the `duration` property (represented in milliseconds). You can also
    # configure the transition function by setting the `animation` property.
    #
    # Possible values for `animation`
    # `Ease`
    # `EaseOut`
    # `EaseOutSine`
    # `EaseOutQuad`
    # `EaseOutCubic`
    # `EaseOutQuart`
    # `EaseOutQuint`
    # `EaseOutExpo`
    # `EaseOutCirc`
    # `Linear`
    #
    # To completely disable the visual bell, set its duration to 0.
    #
    visual_bell:
      animation: EaseOutExpo
      duration: 0

    # Key bindings
    #
    # Each binding is defined as an object with some properties. Most of the
    # properties are optional. All of the alphabetical keys should have a letter for
    # the `key` value such as `V`. Function keys are probably what you would expect
    # as well (F1, F2, ..). The number keys above the main keyboard are encoded as
    # `Key1`, `Key2`, etc. Keys on the number pad are encoded `Number1`, `Number2`,
    # etc.  These all match the glutin::VirtualKeyCode variants.
    #
    # Possible values for `mods`
    # `Command`, `Super` refer to the super/command/windows key
    # `Control` for the control key
    # `Shift` for the Shift key
    # `Alt` and `Option` refer to alt/option
    #
    # mods may be combined with a `|`. For example, requiring control and shift
    # looks like:
    #
    # mods: Control|Shift
    #
    # The parser is currently quite sensitive to whitespace and capitalization -
    # capitalization must match exactly, and piped items must not have whitespace
    # around them.
    #
    # Either an `action` or `chars` field must be present. `chars` writes the
    # specified string every time that binding is activated. These should generally
    # be escape sequences, but they can be configured to send arbitrary strings of
    # bytes. Possible values of `action` include `Paste` and `PasteSelection`.
    #
    # Want to add a binding (e.g. "PageUp") but are unsure what the X sequence
    # (e.g. "\x1b[5~") is? Open another terminal (like xterm) without tmux,
    # then run `showkey -a` to get the sequence associated to a key combination.
    key_bindings:
      - { key: V,        mods: Control|Shift,    action: Paste               }
      - { key: C,        mods: Control|Shift,    action: Copy                }
      - { key: Q,        mods: Command, action: Quit                         }
      - { key: W,        mods: Command, action: Quit                         }
      - { key: Insert,   mods: Shift,   action: PasteSelection               }
      - { key: Home,                    chars: "\x1bOH",   mode: AppCursor   }
      - { key: Home,                    chars: "\x1b[1~",  mode: ~AppCursor  }
      - { key: End,                     chars: "\x1bOF",   mode: AppCursor   }
      - { key: End,                     chars: "\x1b[4~",  mode: ~AppCursor  }
      - { key: PageUp,   mods: Shift,   chars: "\x1b[5;2~"                   }
      - { key: PageUp,   mods: Control, chars: "\x1b[5;5~"                   }
      - { key: PageUp,                  chars: "\x1b[5~"                     }
      - { key: PageDown, mods: Shift,   chars: "\x1b[6;2~"                   }
      - { key: PageDown, mods: Control, chars: "\x1b[6;5~"                   }
      - { key: PageDown,                chars: "\x1b[6~"                     }
      - { key: Left,     mods: Shift,   chars: "\x1b[1;2D"                   }
      - { key: Left,     mods: Control, chars: "\x1b[1;5D"                   }
      - { key: Left,     mods: Alt,     chars: "\x1b[1;3D"                   }
      - { key: Left,                    chars: "\x1b[D",   mode: ~AppCursor  }
      - { key: Left,                    chars: "\x1bOD",   mode: AppCursor   }
      - { key: Right,    mods: Shift,   chars: "\x1b[1;2C"                   }
      - { key: Right,    mods: Control, chars: "\x1b[1;5C"                   }
      - { key: Right,    mods: Alt,     chars: "\x1b[1;3C"                   }
      - { key: Right,                   chars: "\x1b[C",   mode: ~AppCursor  }
      - { key: Right,                   chars: "\x1bOC",   mode: AppCursor   }
      - { key: Up,       mods: Shift,   chars: "\x1b[1;2A"                   }
      - { key: Up,       mods: Control, chars: "\x1b[1;5A"                   }
      - { key: Up,       mods: Alt,     chars: "\x1b[1;3A"                   }
      - { key: Up,                      chars: "\x1b[A",   mode: ~AppCursor  }
      - { key: Up,                      chars: "\x1bOA",   mode: AppCursor   }
      - { key: Down,     mods: Shift,   chars: "\x1b[1;2B"                   }
      - { key: Down,     mods: Control, chars: "\x1b[1;5B"                   }
      - { key: Down,     mods: Alt,     chars: "\x1b[1;3B"                   }
      - { key: Down,                    chars: "\x1b[B",   mode: ~AppCursor  }
      - { key: Down,                    chars: "\x1bOB",   mode: AppCursor   }
      - { key: Tab,      mods: Shift,   chars: "\x1b[Z"                      }
      - { key: F1,                      chars: "\x1bOP"                      }
      - { key: F2,                      chars: "\x1bOQ"                      }
      - { key: F3,                      chars: "\x1bOR"                      }
      - { key: F4,                      chars: "\x1bOS"                      }
      - { key: F5,                      chars: "\x1b[15~"                    }
      - { key: F6,                      chars: "\x1b[17~"                    }
      - { key: F7,                      chars: "\x1b[18~"                    }
      - { key: F8,                      chars: "\x1b[19~"                    }
      - { key: F9,                      chars: "\x1b[20~"                    }
      - { key: F10,                     chars: "\x1b[21~"                    }
      - { key: F11,                     chars: "\x1b[23~"                    }
      - { key: F12,                     chars: "\x1b[24~"                    }
      - { key: Back,                    chars: "\x7f"                        }
      - { key: Back,     mods: Alt,     chars: "\x1b\x7f"                    }
      - { key: Insert,                  chars: "\x1b[2~"                     }
      - { key: Delete,                  chars: "\x1b[3~"                     }

    # Mouse bindings
    #
    # Currently doesn't support modifiers. Both the `mouse` and `action` fields must
    # be specified.
    #
    # Values for `mouse`:
    # - Middle
    # - Left
    # - Right
    # - Numeric identifier such as `5`
    #
    # Values for `action`:
    # - Paste
    # - PasteSelection
    # - Copy (TODO)
    mouse_bindings:
      - { mouse: Middle, action: PasteSelection }

    mouse:
      double_click: { threshold: 300 }
      triple_click: { threshold: 300 }
      hide_cursor_when_typing: true

    selection:
      semantic_escape_chars: ",│`|:\"' ()[]{}<>"

    # Shell
    #
    # You can set shell.program to the path of your favorite shell, e.g. /bin/fish.
    # Entries in shell.args are passed unmodified as arguments to the shell.
    #shell:
    #  program: /bin/bash
    #  args:
    #    - --login
  '';

  largeFontConfig = writeText "alacritty-large-font-config" ''
    # Configuration for Alacritty, the GPU enhanced terminal emulator

    # Any items in the `env` entry below will be added as
    # environment variables. Some entries may override variables
    # set by alacritty it self.
    env:
      # TERM env customization.
      #
      # If this property is not set, alacritty will set it to xterm-256color.
      #
      # Note that some xterm terminfo databases don't declare support for italics.
      # You can verify this by checking for the presence of `smso` and `sitm` in
      # `infocmp xterm-256color`.
      TERM: xterm-256color

    window:
      # Window dimensions in character columns and lines
      # (changes require restart)
      dimensions:
        columns: 80
        lines: 24

      # Adds this many blank pixels of padding around the window
      # Units are physical pixels; this is not DPI aware.
      # (change requires restart)
      padding:
        x: 2
        y: 2

    # Display tabs using this many cells (changes require restart)
    tabspaces: 8

    # When true, bold text is drawn using the bright variant of colors.
    draw_bold_text_with_bright_colors: true

    # Font configuration (changes require restart)
    font:
      # The normal (roman) font face to use.
      normal:
        family: ${font}
        # family: monospace # should be "Menlo" or something on macOS.
        # Style can be specified to pick a specific face.
        # style: Regular

      # Point size of the font
      size: ${largeFontSize}

      # Offset is the extra space around each character. offset.y can be thought of
      # as modifying the linespacing, and offset.x as modifying the letter spacing.
      offset:
        x: 0
        y: 0

      # Glyph offset determines the locations of the glyphs within their cells with
      # the default being at the bottom. Increase the x offset to move the glyph to
      # the right, increase the y offset to move the glyph upward.
      glyph_offset:
        x: 0
        y: 0

      # OS X only: use thin stroke font rendering. Thin strokes are suitable
      # for retina displays, but for non-retina you probably want this set to
      # false.
      use_thin_strokes: true

    # Should display the render timer
    debug.render_timer: false

    # background_opacity: 0.95

    ${colors}

    # Visual Bell
    #
    # Any time the BEL code is received, Alacritty "rings" the visual bell. Once
    # rung, the terminal background will be set to white and transition back to the
    # default background color. You can control the rate of this transition by
    # setting the `duration` property (represented in milliseconds). You can also
    # configure the transition function by setting the `animation` property.
    #
    # Possible values for `animation`
    # `Ease`
    # `EaseOut`
    # `EaseOutSine`
    # `EaseOutQuad`
    # `EaseOutCubic`
    # `EaseOutQuart`
    # `EaseOutQuint`
    # `EaseOutExpo`
    # `EaseOutCirc`
    # `Linear`
    #
    # To completely disable the visual bell, set its duration to 0.
    #
    visual_bell:
      animation: EaseOutExpo
      duration: 0

    # Key bindings
    #
    # Each binding is defined as an object with some properties. Most of the
    # properties are optional. All of the alphabetical keys should have a letter for
    # the `key` value such as `V`. Function keys are probably what you would expect
    # as well (F1, F2, ..). The number keys above the main keyboard are encoded as
    # `Key1`, `Key2`, etc. Keys on the number pad are encoded `Number1`, `Number2`,
    # etc.  These all match the glutin::VirtualKeyCode variants.
    #
    # Possible values for `mods`
    # `Command`, `Super` refer to the super/command/windows key
    # `Control` for the control key
    # `Shift` for the Shift key
    # `Alt` and `Option` refer to alt/option
    #
    # mods may be combined with a `|`. For example, requiring control and shift
    # looks like:
    #
    # mods: Control|Shift
    #
    # The parser is currently quite sensitive to whitespace and capitalization -
    # capitalization must match exactly, and piped items must not have whitespace
    # around them.
    #
    # Either an `action` or `chars` field must be present. `chars` writes the
    # specified string every time that binding is activated. These should generally
    # be escape sequences, but they can be configured to send arbitrary strings of
    # bytes. Possible values of `action` include `Paste` and `PasteSelection`.
    #
    # Want to add a binding (e.g. "PageUp") but are unsure what the X sequence
    # (e.g. "\x1b[5~") is? Open another terminal (like xterm) without tmux,
    # then run `showkey -a` to get the sequence associated to a key combination.
    key_bindings:
      - { key: V,        mods: Control|Shift,    action: Paste               }
      - { key: C,        mods: Control|Shift,    action: Copy                }
      - { key: Q,        mods: Command, action: Quit                         }
      - { key: W,        mods: Command, action: Quit                         }
      - { key: Insert,   mods: Shift,   action: PasteSelection               }
      - { key: Home,                    chars: "\x1bOH",   mode: AppCursor   }
      - { key: Home,                    chars: "\x1b[1~",  mode: ~AppCursor  }
      - { key: End,                     chars: "\x1bOF",   mode: AppCursor   }
      - { key: End,                     chars: "\x1b[4~",  mode: ~AppCursor  }
      - { key: PageUp,   mods: Shift,   chars: "\x1b[5;2~"                   }
      - { key: PageUp,   mods: Control, chars: "\x1b[5;5~"                   }
      - { key: PageUp,                  chars: "\x1b[5~"                     }
      - { key: PageDown, mods: Shift,   chars: "\x1b[6;2~"                   }
      - { key: PageDown, mods: Control, chars: "\x1b[6;5~"                   }
      - { key: PageDown,                chars: "\x1b[6~"                     }
      - { key: Left,     mods: Shift,   chars: "\x1b[1;2D"                   }
      - { key: Left,     mods: Control, chars: "\x1b[1;5D"                   }
      - { key: Left,     mods: Alt,     chars: "\x1b[1;3D"                   }
      - { key: Left,                    chars: "\x1b[D",   mode: ~AppCursor  }
      - { key: Left,                    chars: "\x1bOD",   mode: AppCursor   }
      - { key: Right,    mods: Shift,   chars: "\x1b[1;2C"                   }
      - { key: Right,    mods: Control, chars: "\x1b[1;5C"                   }
      - { key: Right,    mods: Alt,     chars: "\x1b[1;3C"                   }
      - { key: Right,                   chars: "\x1b[C",   mode: ~AppCursor  }
      - { key: Right,                   chars: "\x1bOC",   mode: AppCursor   }
      - { key: Up,       mods: Shift,   chars: "\x1b[1;2A"                   }
      - { key: Up,       mods: Control, chars: "\x1b[1;5A"                   }
      - { key: Up,       mods: Alt,     chars: "\x1b[1;3A"                   }
      - { key: Up,                      chars: "\x1b[A",   mode: ~AppCursor  }
      - { key: Up,                      chars: "\x1bOA",   mode: AppCursor   }
      - { key: Down,     mods: Shift,   chars: "\x1b[1;2B"                   }
      - { key: Down,     mods: Control, chars: "\x1b[1;5B"                   }
      - { key: Down,     mods: Alt,     chars: "\x1b[1;3B"                   }
      - { key: Down,                    chars: "\x1b[B",   mode: ~AppCursor  }
      - { key: Down,                    chars: "\x1bOB",   mode: AppCursor   }
      - { key: Tab,      mods: Shift,   chars: "\x1b[Z"                      }
      - { key: F1,                      chars: "\x1bOP"                      }
      - { key: F2,                      chars: "\x1bOQ"                      }
      - { key: F3,                      chars: "\x1bOR"                      }
      - { key: F4,                      chars: "\x1bOS"                      }
      - { key: F5,                      chars: "\x1b[15~"                    }
      - { key: F6,                      chars: "\x1b[17~"                    }
      - { key: F7,                      chars: "\x1b[18~"                    }
      - { key: F8,                      chars: "\x1b[19~"                    }
      - { key: F9,                      chars: "\x1b[20~"                    }
      - { key: F10,                     chars: "\x1b[21~"                    }
      - { key: F11,                     chars: "\x1b[23~"                    }
      - { key: F12,                     chars: "\x1b[24~"                    }
      - { key: Back,                    chars: "\x7f"                        }
      - { key: Back,     mods: Alt,     chars: "\x1b\x7f"                    }
      - { key: Insert,                  chars: "\x1b[2~"                     }
      - { key: Delete,                  chars: "\x1b[3~"                     }

    # Mouse bindings
    #
    # Currently doesn't support modifiers. Both the `mouse` and `action` fields must
    # be specified.
    #
    # Values for `mouse`:
    # - Middle
    # - Left
    # - Right
    # - Numeric identifier such as `5`
    #
    # Values for `action`:
    # - Paste
    # - PasteSelection
    # - Copy (TODO)
    mouse_bindings:
      - { mouse: Middle, action: PasteSelection }

    mouse:
      double_click: { threshold: 300 }
      triple_click: { threshold: 300 }
      hide_cursor_when_typing: true

    selection:
      semantic_escape_chars: ",│`|:\"' ()[]{}<>"

    # Shell
    #
    # You can set shell.program to the path of your favorite shell, e.g. /bin/fish.
    # Entries in shell.args are passed unmodified as arguments to the shell.
    #shell:
    #  program: /bin/bash
    #  args:
    #    - --login
  '';

  launcherConfig = writeText "alacritty-launcher-config" ''
    # Configuration for Alacritty, the GPU enhanced terminal emulator

    # Any items in the `env` entry below will be added as
    # environment variables. Some entries may override variables
    # set by alacritty it self.
    env:
      # TERM env customization.
      #
      # If this property is not set, alacritty will set it to xterm-256color.
      #
      # Note that some xterm terminfo databases don't declare support for italics.
      # You can verify this by checking for the presence of `smso` and `sitm` in
      # `infocmp xterm-256color`.
      TERM: xterm-256color

    window:
      # Window dimensions in character columns and lines
      # (changes require restart)
      dimensions:
        columns: 80
        lines: 24

      # Adds this many blank pixels of padding around the window
      # Units are physical pixels; this is not DPI aware.
      # (change requires restart)
      padding:
        x: 2
        y: 2

    # Display tabs using this many cells (changes require restart)
    tabspaces: 8

    # When true, bold text is drawn using the bright variant of colors.
    draw_bold_text_with_bright_colors: true

    # Font configuration (changes require restart)
    font:
      # The normal (roman) font face to use.
      normal:
        family: Roboto Mono Nerd Font
        # family: monospace # should be "Menlo" or something on macOS.
        # Style can be specified to pick a specific face.
        # style: Regular

      # Point size of the font
      size: ${largeFontSize}

      # Offset is the extra space around each character. offset.y can be thought of
      # as modifying the linespacing, and offset.x as modifying the letter spacing.
      offset:
        x: 0
        y: 0

      # Glyph offset determines the locations of the glyphs within their cells with
      # the default being at the bottom. Increase the x offset to move the glyph to
      # the right, increase the y offset to move the glyph upward.
      glyph_offset:
        x: 0
        y: 0

      # OS X only: use thin stroke font rendering. Thin strokes are suitable
      # for retina displays, but for non-retina you probably want this set to
      # false.
      use_thin_strokes: true

    # Should display the render timer
    debug.render_timer: false

    background_opacity: 0.85

    colors:
      primary:
        background: '0x004341'
        foreground: '0xffffff'

    # Visual Bell
    #
    # Any time the BEL code is received, Alacritty "rings" the visual bell. Once
    # rung, the terminal background will be set to white and transition back to the
    # default background color. You can control the rate of this transition by
    # setting the `duration` property (represented in milliseconds). You can also
    # configure the transition function by setting the `animation` property.
    #
    # Possible values for `animation`
    # `Ease`
    # `EaseOut`
    # `EaseOutSine`
    # `EaseOutQuad`
    # `EaseOutCubic`
    # `EaseOutQuart`
    # `EaseOutQuint`
    # `EaseOutExpo`
    # `EaseOutCirc`
    # `Linear`
    #
    # To completely disable the visual bell, set its duration to 0.
    #
    visual_bell:
      animation: EaseOutExpo
      duration: 0

    # Key bindings
    #
    # Each binding is defined as an object with some properties. Most of the
    # properties are optional. All of the alphabetical keys should have a letter for
    # the `key` value such as `V`. Function keys are probably what you would expect
    # as well (F1, F2, ..). The number keys above the main keyboard are encoded as
    # `Key1`, `Key2`, etc. Keys on the number pad are encoded `Number1`, `Number2`,
    # etc.  These all match the glutin::VirtualKeyCode variants.
    #
    # Possible values for `mods`
    # `Command`, `Super` refer to the super/command/windows key
    # `Control` for the control key
    # `Shift` for the Shift key
    # `Alt` and `Option` refer to alt/option
    #
    # mods may be combined with a `|`. For example, requiring control and shift
    # looks like:
    #
    # mods: Control|Shift
    #
    # The parser is currently quite sensitive to whitespace and capitalization -
    # capitalization must match exactly, and piped items must not have whitespace
    # around them.
    #
    # Either an `action` or `chars` field must be present. `chars` writes the
    # specified string every time that binding is activated. These should generally
    # be escape sequences, but they can be configured to send arbitrary strings of
    # bytes. Possible values of `action` include `Paste` and `PasteSelection`.
    #
    # Want to add a binding (e.g. "PageUp") but are unsure what the X sequence
    # (e.g. "\x1b[5~") is? Open another terminal (like xterm) without tmux,
    # then run `showkey -a` to get the sequence associated to a key combination.
    key_bindings:
      - { key: V,        mods: Control|Shift,    action: Paste               }
      - { key: C,        mods: Control|Shift,    action: Copy                }
      - { key: Q,        mods: Command, action: Quit                         }
      - { key: W,        mods: Command, action: Quit                         }
      - { key: Insert,   mods: Shift,   action: PasteSelection               }
      - { key: Home,                    chars: "\x1bOH",   mode: AppCursor   }
      - { key: Home,                    chars: "\x1b[1~",  mode: ~AppCursor  }
      - { key: End,                     chars: "\x1bOF",   mode: AppCursor   }
      - { key: End,                     chars: "\x1b[4~",  mode: ~AppCursor  }
      - { key: PageUp,   mods: Shift,   chars: "\x1b[5;2~"                   }
      - { key: PageUp,   mods: Control, chars: "\x1b[5;5~"                   }
      - { key: PageUp,                  chars: "\x1b[5~"                     }
      - { key: PageDown, mods: Shift,   chars: "\x1b[6;2~"                   }
      - { key: PageDown, mods: Control, chars: "\x1b[6;5~"                   }
      - { key: PageDown,                chars: "\x1b[6~"                     }
      - { key: Left,     mods: Shift,   chars: "\x1b[1;2D"                   }
      - { key: Left,     mods: Control, chars: "\x1b[1;5D"                   }
      - { key: Left,     mods: Alt,     chars: "\x1b[1;3D"                   }
      - { key: Left,                    chars: "\x1b[D",   mode: ~AppCursor  }
      - { key: Left,                    chars: "\x1bOD",   mode: AppCursor   }
      - { key: Right,    mods: Shift,   chars: "\x1b[1;2C"                   }
      - { key: Right,    mods: Control, chars: "\x1b[1;5C"                   }
      - { key: Right,    mods: Alt,     chars: "\x1b[1;3C"                   }
      - { key: Right,                   chars: "\x1b[C",   mode: ~AppCursor  }
      - { key: Right,                   chars: "\x1bOC",   mode: AppCursor   }
      - { key: Up,       mods: Shift,   chars: "\x1b[1;2A"                   }
      - { key: Up,       mods: Control, chars: "\x1b[1;5A"                   }
      - { key: Up,       mods: Alt,     chars: "\x1b[1;3A"                   }
      - { key: Up,                      chars: "\x1b[A",   mode: ~AppCursor  }
      - { key: Up,                      chars: "\x1bOA",   mode: AppCursor   }
      - { key: Down,     mods: Shift,   chars: "\x1b[1;2B"                   }
      - { key: Down,     mods: Control, chars: "\x1b[1;5B"                   }
      - { key: Down,     mods: Alt,     chars: "\x1b[1;3B"                   }
      - { key: Down,                    chars: "\x1b[B",   mode: ~AppCursor  }
      - { key: Down,                    chars: "\x1bOB",   mode: AppCursor   }
      - { key: Tab,      mods: Shift,   chars: "\x1b[Z"                      }
      - { key: F1,                      chars: "\x1bOP"                      }
      - { key: F2,                      chars: "\x1bOQ"                      }
      - { key: F3,                      chars: "\x1bOR"                      }
      - { key: F4,                      chars: "\x1bOS"                      }
      - { key: F5,                      chars: "\x1b[15~"                    }
      - { key: F6,                      chars: "\x1b[17~"                    }
      - { key: F7,                      chars: "\x1b[18~"                    }
      - { key: F8,                      chars: "\x1b[19~"                    }
      - { key: F9,                      chars: "\x1b[20~"                    }
      - { key: F10,                     chars: "\x1b[21~"                    }
      - { key: F11,                     chars: "\x1b[23~"                    }
      - { key: F12,                     chars: "\x1b[24~"                    }
      - { key: Back,                    chars: "\x7f"                        }
      - { key: Back,     mods: Alt,     chars: "\x1b\x7f"                    }
      - { key: Insert,                  chars: "\x1b[2~"                     }
      - { key: Delete,                  chars: "\x1b[3~"                     }

    # Mouse bindings
    #
    # Currently doesn't support modifiers. Both the `mouse` and `action` fields must
    # be specified.
    #
    # Values for `mouse`:
    # - Middle
    # - Left
    # - Right
    # - Numeric identifier such as `5`
    #
    # Values for `action`:
    # - Paste
    # - PasteSelection
    # - Copy (TODO)
    mouse_bindings:
      - { mouse: Middle, action: PasteSelection }

    mouse:
      double_click: { threshold: 300 }
      triple_click: { threshold: 300 }
      hide_cursor_when_typing: true

    selection:
      semantic_escape_chars: ",│`|:\"' ()[]{}<>"

    # Shell
    #
    # You can set shell.program to the path of your favorite shell, e.g. /bin/fish.
    # Entries in shell.args are passed unmodified as arguments to the shell.
    #shell:
    #  program: /bin/bash
    #  args:
    #    - --login
  '';

in


  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/alacritty"; }}
      ${libdot.copy { path = defaultConfig;
                      to = ".config/alacritty/alacritty.yml"; }}
      ${libdot.copy { path = largeFontConfig;
                      to = ".config/alacritty/alacritty-large-font.yml"; }}
      ${libdot.copy { path = launcherConfig;
                      to = ".config/alacritty/alacritty-launcher.yml"; }}
    '';
  }