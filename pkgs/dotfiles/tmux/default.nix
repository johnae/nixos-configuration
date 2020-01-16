{stdenv, libdot, writeText, fetchFromGitHub, ...}:

let

  nordTheme = fetchFromGitHub {
    owner = "arcticicestudio";
    repo = "nord-tmux";
    rev = "b0fd5838dbd5f3cf55eefd83ac84f3f9ac076610";
    sha256 = "14xhh49izvjw4ycwq5gx4if7a0bcnvgsf3irywc3qps6jjcf5ymk";
  };

  config = writeText "tmux.conf" ''
    ## 24-bit please
    set-option -g default-terminal "xterm-256color"
    set-option -ga terminal-overrides ",*256col*:Tc"

    set-option -sg escape-time 20
    set-option -g prefix C-a
    set-option -g mode-keys vi
    set-option -g mouse on
    set-option -g set-clipboard on

    unbind C-b
    unbind C-a
    bind C-a send-prefix

    bind Escape copy-mode
    bind -T copy-mode-vi Escape send -X cancel
    bind -T copy-mode-vi v send -X begin-selection
    bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

    run-shell ${nordTheme}/nord.tmux
  '';

in

  {
    __toString = self: ''
      ${libdot.copy { path = config; to = ".tmux.conf";  }}
    '';
  }

