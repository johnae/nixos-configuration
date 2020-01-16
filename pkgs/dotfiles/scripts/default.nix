{
   stdenv, lib, libdot
 , writeScriptBin, writeTextFile
 , writeStrictShellScriptBin
 , my-emacs, termite, wl-clipboard
 , ps, jq, fire, sway, rofi, evolution
 , fd, fzf, skim, bashInteractive
 , pass, wpa_supplicant, cloud-sql-proxy
 , gnupg, gawk, gnused, openssl
 , gnugrep, findutils, coreutils
 , alacritty, libnotify, hostname
 , maim, slop, killall, wget, procps
 , openssh, kubectl, diffutils
 , browser, chromium, settings
 , nix-prefetch-github, signal-desktop
 , ...
}:

let
  emacsclient = "${my-emacs}/bin/emacsclient";
  emacs = "${my-emacs}/bin/emacs";

  random-name = writeStrictShellScriptBin "random-name" ''
    NAME=''${1:-}
    if [ -z "$NAME" ]; then
      echo "Please provide a base name as the only argument"
      exit 1
    fi
    echo "$NAME-$(openssl rand 4 -hex)"
  '';

  emacs-server = writeStrictShellScriptBin "emacs-server" ''
    FORCE=''${1:-}
    if [ "$FORCE" == "--force" ]; then
       ${procps}/bin/pkill -f "emacs --daemon=server"
    elif [ -e /run/user/1337/emacs1337/server ]; then
       exit 0
    fi
    ${coreutils}/bin/rm -rf /run/user/1337/emacs1337
    TMPDIR=/run/user/1337 exec ${emacs} --daemon=server
  '';

  edit = writeStrictShellScriptBin "edit" ''
    ${emacs-server}/bin/emacs-server
    exec ${emacsclient} -n -c \
         -s /run/user/1337/emacs1337/server "$@" >/dev/null 2>&1
  '';

  edi = writeStrictShellScriptBin "edi" ''
    ${emacs-server}/bin/emacs-server
    export TERM=xterm-24bits
    exec ${emacsclient} -t -s /run/user/1337/emacs1337/server "$@"
  '';

  emacs-run = writeStrictShellScriptBin "emacs-run" ''
    exec ${emacsclient} -s /run/user/1337/emacs1337/server "$@"
  '';

  ed = writeStrictShellScriptBin "ed" ''
    ${emacs-server}/bin/emacs-server
    exec ${emacsclient} -c -s /run/user/1337/emacs1337/server "$@" >/dev/null 2>&1
  '';

  csp = writeStrictShellScriptBin "csp" ''
    CLOUD_SQL_INSTANCES=''${CLOUD_SQL_INSTANCES:-}
    if [ -z "$CLOUD_SQL_INSTANCES" ]; then
      echo "Please set CLOUD_SQL_INSTANCES env var"
      exit 1
    fi
    exec ${cloud-sql-proxy}/bin/cloud_sql_proxy \
                   -instances="$CLOUD_SQL_INSTANCES"
  '';

  fzf-fzf = writeStrictShellScriptBin "fzf-fzf" ''
    FZF_MIN_HEIGHT=''${FZF_MIN_HEIGHT:-100}
    FZF_MARGIN=''${FZF_MARGIN:-5,5,5,5}
    FZF_PROMPT=''${FZF_PROMPT:- >}
    export FZF_DEFAULT_OPTS=''${FZF_OPTS:-"--reverse"}
    exec ${fzf}/bin/fzf --min-height="$FZF_MIN_HEIGHT" \
        --margin="$FZF_MARGIN" \
        --prompt="$FZF_PROMPT"
  '';

  git-credential-pass = writeStrictShellScriptBin "git-credential-pass" ''
    passfile="$1"
    echo password="$(${pass}/bin/pass show "$passfile" | head -1)"
  '';

  sk-sk = writeStrictShellScriptBin "sk-sk" ''
    SK_MIN_HEIGHT=''${SK_MIN_HEIGHT:-100}
    SK_MARGIN=''${SK_MARGIN:-5,5,5,5}
    SK_PROMPT=''${SK_PROMPT:- >}
    export SKIM_DEFAULT_OPTIONS=''${SK_OPTS:-"--reverse"}
    exec ${skim}/bin/sk --min-height="$SK_MIN_HEIGHT" \
        --margin="$SK_MARGIN" \
        --prompt="$SK_PROMPT"
  '';

  project-select = writeStrictShellScriptBin "project-select" ''
    projects=$*
    if [ -z "$projects" ]; then
      ${coreutils}/bin/echo "Please provide the project root directories to search as arguments"
      exit 1
    fi
    export SK_PROMPT="goto project >"
    export SK_OPTS="--tac --reverse"
    # shellcheck disable=SC2086
    ${fd}/bin/fd -d 8 -pHI -t f '.*\.git/config|.*\.projectile' $projects | \
      ${gnused}/bin/sed -e 's|/\.git/config||g' \
                        -e 's|/\.projectile||g' \
                        -e "s|$HOME/||g" | \
      ${sk-sk}/bin/sk-sk | \
      ${findutils}/bin/xargs -I{} ${coreutils}/bin/echo "$HOME/{}"
  '';

  spotify-cmd = writeStrictShellScriptBin "spotify-cmd" ''
    CMD="$1"
    echo "$CMD" "$@" > "$XDG_RUNTIME_DIR"/spotnix_input
  '';

  spotify-play = writeStrictShellScriptBin "spotify-play" ''
    TYPE="$1"
    set +e
    search="$(SK_OPTS="--print-query" ${sk-sk}/bin/sk-sk < /dev/null)"
    set -e
    echo "$TYPE" "$search" > "$XDG_RUNTIME_DIR"/spotnix_input
    ${sk-sk}/bin/sk-sk < "$XDG_RUNTIME_DIR"/spotnix_output | \
        awk '{print $NF}' | xargs -r -I{} echo play {} > "$XDG_RUNTIME_DIR"/spotnix_input
  '';

  spotify-play-track = writeStrictShellScriptBin "spotify-play-track" ''
    exec ${spotify-play}/bin/spotify-play s
  '';

  spotify-play-artist = writeStrictShellScriptBin "spotify-play-artist" ''
    exec ${spotify-play}/bin/spotify-play sar
  '';

  spotify-play-album = writeStrictShellScriptBin "spotify-play-album" ''
    exec ${spotify-play}/bin/spotify-play sab
  '';

  spotify-play-playlist = writeStrictShellScriptBin "spotify-play-playlist" ''
    exec ${spotify-play}/bin/spotify-play sap
  '';

  screenshot = writeStrictShellScriptBin "screenshot" ''
    name=$(${coreutils}/bin/date +%Y-%m-%d_%H:%M:%S_screen)
    output_dir=$HOME/Pictures/screenshots
    fmt=png
    ${coreutils}/bin/mkdir -p "$output_dir"
    ${maim}/bin/maim -s --format="$fmt $output_dir/$name.$fmt"
  '';

  browse = writeStrictShellScriptBin "browse" ''
    exec ${browser} -P default-nightly "$@"
  '';

  slacks = writeStrictShellScriptBin "slacks" ''
    WS=''${1:-${settings.default-slackws}}
    if [ -z "$WS" ]; then
      echo Please provide a workspace as argument
      exit 1
    fi
    exec ${browser} -P default-nightly --new-window "https://$WS.slack.com"
  '';

  spotifyweb = writeStrictShellScriptBin "spotifyweb" ''
    exec ${browser} -P default-nightly --new-window "https://open.spotify.com"
  '';

  browse-chromium = writeStrictShellScriptBin "browse-chromium" ''
    export GDK_BACKEND=x11
    exec ${chromium}/bin/chromium
  '';

  signal = writeStrictShellScriptBin "signal" ''
    export GDK_BACKEND=x11
    exec ${signal-desktop}/bin/signal-desktop
  '';

  terminal = writeStrictShellScriptBin "terminal" ''
    _TERMEMU=''${_TERMEMU:-}
    TERMINAL_CONFIG=''${TERMINAL_CONFIG:-}
    if [ "$_TERMEMU" = "termite" ]; then
      CONFIG=$HOME/.config/termite/config$TERMINAL_CONFIG
      ${termite}/bin/termite --config "$CONFIG" "$@"
    else
      CONFIG=$HOME/.config/alacritty/alacritty$TERMINAL_CONFIG.yml
      # shellcheck disable=SC2068
      ${alacritty}/bin/alacritty --config-file "$CONFIG" $@
    fi
  '';

  symbols = writeTextFile {
     name = "program-symbols";
     text = libdot.setToStringSep "\n" settings.program-symbols (name: symbol: "${name} ${symbol}");
  };

  launch = writeStrictShellScriptBin "launch" ''
    cmd=$*
    _USE_NAME=''${_USE_NAME:-}
    if [ -z "$cmd" ]; then
      read -r cmd
    fi
    MSG=${sway}/bin/swaymsg
    unset _TERMEMU
    name=$(${coreutils}/bin/echo "$cmd" | ${gawk}/bin/awk '{print $1}')
    if [ "$_USE_NAME" ]; then
        name=$_USE_NAME
        unset _USE_NAME
    else
      set +e
      sym=$(${gnugrep}/bin/grep -E "^$name " ${symbols} | ${gawk}/bin/awk '{print $2}')
      set -e
      if [ "$sym" != "" ]; then
        name="$sym"
      fi
    fi
    wsname=$($MSG -t get_workspaces | ${jq}/bin/jq -r \
             '.[] | select(.focused).name')
    apps=$($MSG -t get_workspaces | ${jq}/bin/jq -r \
             '.[] | select(.focused).focus | length')
    floating=$($MSG -t get_workspaces | ${jq}/bin/jq -r \
             '.[] | select(.focused).floating_nodes | length')
    apps=$((apps - floating))
    if [ "$apps" = "0" ]; then
      wsname=$(${coreutils}/bin/echo "$wsname" | ${gawk}/bin/awk -F':' '{print $1}')
    fi
    set +e
    if ${coreutils}/bin/echo "$wsname" | \
       ${gnugrep}/bin/grep -E '^[0-9]+:? ?+$' > /dev/null; then
      $MSG "rename workspace to \"$wsname: $name\"" >/dev/null 2>&1
    fi
    set -e
    echo "${fire}/bin/fire $cmd" | ${stdenv.shell}
  '';

  rename-workspace = writeStrictShellScriptBin "rename-workspace" ''
    CMD=${sway}/bin/swaymsg
    WSNUM=$($CMD -t get_workspaces | ${jq}/bin/jq \
            '.[] | select(.focused==true).name' | \
            ${coreutils}/bin/cut -d"\"" -f2 | \
            ${gnugrep}/bin/grep -o -E '[[:digit:]]+')
    if [ -z "$*" ]; then
        exit 0
    fi
    $CMD "rename workspace to \"$WSNUM: $*\"" >/dev/null 2>&1
  '';

  fzf-run = writeScriptBin "fzf-run" ''
    #!${bashInteractive}/bin/bash
    export FZF_PROMPT="run >> "
    export FZF_OPTS="$FZF_OPTS''${FZF_OPTS:+ }--no-bold --no-color --height=40 --no-hscroll --no-mouse --no-extended --print-query --reverse"

    compgen -c | \
    sort -u | \
    ${gawk}/bin/awk '{ if (length($0) > 2) print }' | \
    ${gnugrep}/bin/grep -v -E '^\..*' | \
    fzf-fzf | \
    tail -n1 | \
    ${findutils}/bin/xargs -r ${launch}/bin/launch
  '';

  sk-run = writeScriptBin "sk-run" ''
    #!${bashInteractive}/bin/bash
    export SK_PROMPT="run >> "
    export SK_OPTS="$SK_OPTS''${SK_OPTS:+ }--no-bold --color BW --height=40 --no-hscroll --no-mouse --print-query --reverse"

    compgen -c | \
    sort -u | \
    ${gawk}/bin/awk '{ if (length($0) > 2) print }' | \
    ${gnugrep}/bin/grep -v -E '^\..*' | \
    ${sk-sk}/bin/sk-sk | \
    tail -n1 | \
    ${findutils}/bin/xargs -r ${launch}/bin/launch
  '';

  fzf-window = writeStrictShellScriptBin "fzf-window" ''
    cmd=''${1:-}
    if [ -z "$cmd" ]; then
      echo "Please provide a command to run in the window as the argument"
      exit 1
    fi
    shift
    export _TERMEMU=termite
    export TERMINAL_CONFIG=-launcher
    if ${ps}/bin/ps aux | ${gnugrep}/bin/grep '\-t fzf-window' | \
       ${gnugrep}/bin/grep -v grep > /dev/null 2>&1; then
        ${ps}/bin/ps aux | \
            ${gnugrep}/bin/grep '\-t fzf-window' | \
            ${gnugrep}/bin/grep -v grep | \
            ${gawk}/bin/awk '{print $2}' | \
            ${findutils}/bin/xargs -r -I{} kill {}
        exit
    fi

    exec ${terminal}/bin/terminal -t "fzf-window" -e "$cmd $*"
  '';

  sk-window = writeStrictShellScriptBin "sk-window" ''
    cmd=''${1:-}
    if [ -z "$cmd" ]; then
      echo "Please provide a command to run in the window as the argument"
      exit 1
    fi
    shift
    _TERMEMU=
    #export _TERMEMU=termite
    export TERMINAL_CONFIG=-launcher
    if ${ps}/bin/ps aux | ${gnugrep}/bin/grep '\-t sk-window' | \
       ${gnugrep}/bin/grep -v grep > /dev/null 2>&1; then
        ${ps}/bin/ps aux | \
            ${gnugrep}/bin/grep '\-t sk-window' | \
            ${gnugrep}/bin/grep -v grep | \
            ${gawk}/bin/awk '{print $2}' | \
            ${findutils}/bin/xargs -r -I{} kill {}
        exit
    fi

    if [ "$_TERMEMU" = "termite" ]; then
      exec ${terminal}/bin/terminal -t "sk-window" -e "$cmd" "$@"
    fi
    # shellcheck disable=SC2086
    exec ${terminal}/bin/terminal --class "sk-window" -e $cmd
  '';

  sk-passmenu = writeStrictShellScriptBin "sk-passmenu" ''
    export _TERMEMU=termite
    export SK_PROMPT="copy password >> "
    export SK_OPTS="--no-bold --color BW  --height=40 --reverse --no-hscroll --no-mouse"

    passfile=''${1:-}
    nosubmit=''${nosubmit:-}
    passonly=''${passonly:-}
    _passmenu_didsearch=''${_passmenu_didsearch:-}
    SWAYSOCK=''${SWAYSOCK:-}
    prefix=$(readlink -f "$HOME/.password-store")
    if [ -z "$_passmenu_didsearch" ]; then
      export _passmenu_didsearch=y
      ${fd}/bin/fd --type f -E '/notes/' '.gpg$' "$HOME/.password-store" | \
         ${gnused}/bin/sed "s|$prefix/||g" | ${gnused}/bin/sed 's|.gpg$||g' | \
         ${sk-sk}/bin/sk-sk | \
         ${findutils}/bin/xargs -r -I{} ${coreutils}/bin/echo "$0 {}" | \
         ${launch}/bin/launch
    fi

    if [ "$passfile" = "" ]; then
      exit
    fi

    error_icon=~/Pictures/icons/essential/error.svg

    getlogin() {
      ${coreutils}/bin/echo -n "$(${coreutils}/bin/basename "$1")"
    }

    getpass() {
      ${coreutils}/bin/echo -n "$(${gnupg}/bin/gpg --decrypt "$prefix/$1.gpg" \
                            2>/dev/null | ${coreutils}/bin/head -1)"
    }

    login=$(getlogin "$passfile")
    pass=$(getpass "$passfile")

    if [ "$pass" = "" ]; then
      ${libnotify}/bin/notify-send -i $error_icon -a "Password store" -u critical \
      "Decrypt error" "Error decrypting password file, is your gpg card inserted?"
    else
      if [ -z "$passonly" ]; then
        ${coreutils}/bin/echo -n "$login" | ${wl-clipboard}/bin/wl-copy -onf
        ${coreutils}/bin/echo -n "$pass" | ${wl-clipboard}/bin/wl-copy -onf
      else
        ${coreutils}/bin/echo -n "$pass" | ${wl-clipboard}/bin/wl-copy -onf
      fi
    fi

  '';

  fzf-passmenu = writeStrictShellScriptBin "fzf-passmenu" ''
    export _TERMEMU=termite
    export FZF_PROMPT="copy password >> "
    export FZF_OPTS="--no-bold --no-color --height=40 --reverse --no-hscroll --no-mouse"
    ## because bug: https://github.com/jordansissel/xdotool/issues/49

    passfile=''${1:-}
    nosubmit=''${nosubmit:-}
    passonly=''${passonly:-}
    _passmenu_didsearch=''${_passmenu_didsearch:-}
    SWAYSOCK=''${SWAYSOCK:-}
    prefix=$(readlink -f "$HOME/.password-store")
    if [ -z "$_passmenu_didsearch" ]; then
      export _passmenu_didsearch=y
      ${fd}/bin/fd --type f -E '/notes/' '.gpg$' "$HOME/.password-store" | \
         ${gnused}/bin/sed "s|$prefix/||g" | ${gnused}/bin/sed 's|.gpg$||g' | \
         ${fzf-fzf}/bin/fzf-fzf | \
         ${findutils}/bin/xargs -r -I{} ${coreutils}/bin/echo "$0 {}" | \
         ${launch}/bin/launch
    fi

    if [ "$passfile" = "" ]; then
      exit
    fi

    error_icon=~/Pictures/icons/essential/error.svg

    getlogin() {
      ${coreutils}/bin/echo -n "$(${coreutils}/bin/basename "$1")"
    }

    getpass() {
      ${coreutils}/bin/echo -n "$(${gnupg}/bin/gpg --decrypt "$prefix/$1.gpg" \
                            2>/dev/null | ${coreutils}/bin/head -1)"
    }

    #login=$(getlogin "$passfile")
    pass=$(getpass "$passfile")

    if [ "$pass" = "" ]; then
      ${libnotify}/bin/notify-send -i $error_icon -a "Password store" -u critical \
      "Decrypt error" "Error decrypting password file, is your gpg card inserted?"
    else
      ${coreutils}/bin/echo -n "$pass" | ${wl-clipboard}/bin/wl-copy
    fi

  '';

  rofi-passmenu = writeStrictShellScriptBin "rofi-passmenu" ''
    PROMPT=" for password >"

    prefix=$(readlink -f "$HOME/.password-store")
    nosubmit=''${nosubmit:-}
    passonly=''${passonly:-}
    passfile=$(${fd}/bin/fd --type f -E '/notes/' '.gpg$' "$HOME/.password-store" | \
       ${gnused}/bin/sed "s|$prefix/||g" | ${gnused}/bin/sed 's|.gpg$||g' | \
       ${rofi}/bin/rofi -dmenu -p "$PROMPT")

    if [ "$passfile" = "" ]; then
      exit
    fi

    error_icon=~/Pictures/icons/essential/error.svg

    getlogin() {
      ${coreutils}/bin/echo -n "$(${coreutils}/bin/basename "$1")"
    }

    getpass() {
      ${coreutils}/bin/echo -n "$(${gnupg}/bin/gpg \
          --decrypt "$prefix/$1.gpg" 2>/dev/null | ${coreutils}/bin/head -1)"
    }

    #login=$(getlogin "$passfile")
    pass=$(getpass "$passfile")

    if [ "$pass" = "" ]; then
      ${libnotify}/bin/notify-send -i $error_icon -a "Password store" -u critical \
      "Decrypt error" "Error decrypting password file, is your gpg card inserted?"
    else
      ${coreutils}/bin/echo -n "$pass" | ${wl-clipboard}/bin/wl-copy
    fi
  '';

  update-wireguard-keys = writeStrictShellScriptBin "update-wireguard-keys" ''
    IFS=$'\n'
    HN="$(${hostname}/bin/hostname)"
    mkdir -p ~/.wireguard
    for KEY in $(find ~/.password-store/vpn/wireguard/"$HN"/ -type f -print0 | xargs -0 -I{} basename {}); do
      KEYNAME=$(basename "$KEY" .gpg)
      echo "Ensure wireguard key \"$KEYNAME\" is available"
      ${pass}/bin/pass show "vpn/wireguard/$HN/$KEYNAME" > ~/.wireguard/"$KEYNAME"
      chmod 0600 ~/.wireguard/"$KEYNAME"
    done
  '';

  update-wifi-networks = writeStrictShellScriptBin "update-wifi-networks" ''
    IFS=$'\n'
    for NET in $(find ~/.password-store/wifi/networks/ -type f -print0 | xargs -0 -I{} basename {}); do
      NETNAME=$(basename "$NET" .gpg)
      echo "Ensure wireless network \"$NETNAME\" is available"
      ${pass}/bin/pass show "wifi/networks/$NETNAME" | sudo tee "/var/lib/iwd/$NETNAME.psk" > /dev/null
    done
  '';

  add-wifi-network = writeStrictShellScriptBin "add-wifi-network" ''
    NET=''${1:-}
    PASS=''${2:-}
    if [ -z "$NET" ]; then
      echo Please provide the network as first argument
      exit 1
    fi
    if [ -z "$PASS" ]; then
      echo Please provide the password as second argument
      exit 1
    fi
    PSK=$(${wpa_supplicant}/bin/wpa_passphrase "$1" "$2" | grep "[^#]psk=" | awk -F'=' '{print $2}')
    if [ -z "$PSK" ]; then
      echo Hmm PSK was empty
      exit 1
    fi
    cat <<EOF | ${pass}/bin/pass insert "wifi/networks/$NET"
    [Security]
    PreSharedKey=$PSK
    Passphrase=$PASS
    EOF
    ${update-wifi-networks}/bin/update-wifi-networks
  '';

  random-background = writeStrictShellScriptBin "random-background" ''
    if [ ! -d "$HOME"/Pictures/backgrounds ] ||
       [ "$(${findutils}/bin/find "$HOME"/Pictures/backgrounds/ -type f | wc -l)" = "0" ]; then
       echo "$HOME"/Pictures/default-background.png
       exit
    fi
    ${findutils}/bin/find "$HOME/Pictures/backgrounds" -type f | \
         ${coreutils}/bin/sort -R | ${coreutils}/bin/tail -1
  '';

  random-picsum-background = writeStrictShellScriptBin "random-picsum-background" ''
    ${wget}/bin/wget -O /tmp/wallpaper.jpg 'https://picsum.photos/3200/1800' 2>/dev/null
    if [ -e "$HOME"/Pictures/wallpaper.jpg ]; then
      mv "$HOME"/Pictures/wallpaper.jpg "$HOME"/Pictures/previous-wallpaper.jpg
    fi
    mv /tmp/wallpaper.jpg "$HOME"/Pictures/wallpaper.jpg
    echo "$HOME"/Pictures/wallpaper.jpg
  '';

  start-sway = writeStrictShellScriptBin "start-sway" ''
    #export _TERMEMU=termite
    export XDG_SESSION_TYPE=wayland
    export GDK_BACKEND=wayland
    export GTK_THEME="${settings.dconf."org/gnome/desktop/interface".gtk-theme}"
    export QT_STYLE_OVERRIDE=gtk
    export _JAVA_AWT_WM_NONREPARENTING=1
    export VISUAL=edi
    export EDITOR=$VISUAL
    export PROJECTS=~/Development
    if [ -e .config/syncthing/config.xml ]; then
       SYNCTHING_API_KEY=$(grep apikey < .config/syncthing/config.xml | \
                                awk -F">|</" '{print $2}')
       if [ "$SYNCTHING_API_KEY" != "" ]; then
          export SYNCTHING_API_KEY
       fi
    fi

    exec dbus-launch --exit-with-session sway "$@"
  '';

  mail = writeStrictShellScriptBin "mail" ''
    export TERMINAL_CONFIG=
    exec ${terminal}/bin/terminal -e ${edi}/bin/edi -e '(mu4e)'
  '';

  update-user-nixpkg = writeStrictShellScriptBin "update-user-nixpkg" ''
    metadata=''${1:-} ## the metadata.json file
    if [ -z "$metadata" ]; then
      echo "Please give me the metadata.json"
      exit 1
    fi
    dir="$(dirname "$metadata")"

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NEUTRAL='\033[0m'
    BOLD='\033[1m'

    neutral() { printf "%b" "$NEUTRAL"; }
    start() { printf "%b" "$1"; }
    clr() { start "$1""$2"; neutral; }
    max_retries=2
    retries=$max_retries

    rm -f "$dir"/metadata.tmp.json
    # shellcheck disable=SC2046
    set $(${jq}/bin/jq -r '.owner + " " + .repo' < "$metadata")
    ## above sets $1 and $2

    while true; do
      clr "$NEUTRAL" "Prefetching $1/$2 master branch...\n"
      set +e
      if ! ${nix-prefetch-github}/bin/nix-prefetch-github --rev master "$1" "$2" > "$dir"/metadata.tmp.json; then
        clr "$RED" "ERROR: prefetch of $1/$2 failed\n"
        retries=$((retries - 1))
        clr "$GREEN" "   $1/$2 - retry $((max_retries - retries)) of $max_retries\n"
        if [[ "$retries" -ne "0" ]]; then
          continue
        else
          clr "$RED" "FAIL: $1/$2 failed prefetch even after retrying\n"
          exit 1
        fi
      fi
      set -e
      clr "$BOLD" "Completed prefetching $1/$2...\n"

      if [ ! -s "$dir"/metadata.tmp.json ]; then
          clr "$RED" "ERROR: $dir/metadata.tmp.json is empty\n"
          if [[ "$retries" -ne "0" ]]; then
            retries=$((retries - 1))
            clr "$GREEN" "   $1/$2 - retry $((max_retries - retries)) of $max_retries\n"
            continue
          else
            clr "$RED" "FAIL: $dir/metadata.tmp.json is empty even after retrying\n"
            exit 1
          fi
          exit 1
      fi
      break
    done

    if ! ${jq}/bin/jq < "$dir"/metadata.tmp.json > /dev/null; then
        clr "$RED" "ERROR: $dir/metadata.tmp.json is not valid json\n"
        cat "$dir"/metadata.tmp.json
        exit 1
    fi

  '';

  update-user-nixpkgs = writeStrictShellScriptBin "update-user-nixpkgs" ''

    #RED='\033[0;31m'
    GREEN='\033[0;32m'
    NEUTRAL='\033[0m'
    BOLD='\033[1m'

    neutral() { printf "%b" "$NEUTRAL"; }
    start() { printf "%b" "$1"; }
    clr() { start "$1""$2"; neutral; }

    echo Updating metadata.json files in ~/.config/nixpkgs/packages...

    #for pkg in ~/.config/nixpkgs/packages/*; do
    ${findutils}/bin/find ~/.config/nixpkgs/packages/ -type f -name metadata.json | \
      ${findutils}/bin/xargs -I{} -n1 -P3 ${update-user-nixpkg}/bin/update-user-nixpkg {}

    pkgs_updated=0
    for pkg in ~/.config/nixpkgs/packages/*; do
        if [ -d "$pkg" ] && [ -e "$pkg"/metadata.tmp.json ]; then
           if ! ${diffutils}/bin/diff "$pkg"/metadata.json "$pkg"/metadata.tmp.json > /dev/null; then
             pkgs_updated=$((pkgs_updated + 1))
             clr "$BOLD" "Package $(basename "$pkg") was updated\n"
             mv "$pkg"/metadata.tmp.json "$pkg"/metadata.json
           fi
           rm -f "$pkg"/metadata.tmp.json
        fi
    done

    if [ "$pkgs_updated" -gt 0 ]; then
      clr "$BOLD" "$pkgs_updated packages were updated\n"
    else
      clr "$GREEN" "No package metadata was updated\n"
    fi
  '';

in

  {
    paths = {
      inherit edit edi ed emacs-run
              emacs-server mail
              fzf-fzf project-select
              terminal launch csp
              fzf-passmenu rofi-passmenu
              fzf-run fzf-window git-credential-pass
              sk-sk sk-run sk-window sk-passmenu
              browse slacks spotifyweb browse-chromium signal
              rename-workspace screenshot
              start-sway random-background random-name
              random-picsum-background
              add-wifi-network update-wifi-networks
              update-user-nixpkg update-user-nixpkgs update-wireguard-keys
              spotify-play-album spotify-play-track spotify-cmd
              spotify-play-artist spotify-play-playlist;
    };
  }
