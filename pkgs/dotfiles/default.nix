{stdenv, lib, pkgs, ...}:

with lib;

let

  libdot = pkgs.callPackage ./libdot.nix { };
  toShell = libdot.setToStringSep "\n";

  settings = import (builtins.getEnv "HOME") { inherit stdenv lib pkgs libdot; };

  scripts = (with libdot; pkgs.callPackage ./scripts {
          browser = "${pkgs.latest.firefox-nightly-bin}/bin/firefox";
          evolution = pkgs.gnome3.evolution;
          inherit libdot settings writeStrictShellScriptBin;
          }).paths;


  i3statusconf = pkgs.callPackage ./i3status-rust { inherit libdot settings; };

  swaydot = with scripts; with libdot; pkgs.callPackage ./sway {
        inherit libdot browse launch edi edit random-background
                random-picsum-background emacs-server terminal
                fzf-window fzf-run fzf-passmenu sk-window sk-run
                sk-passmenu rofi-passmenu rename-workspace screenshot
                spotify-play-album spotify-play-artist spotify-cmd
                spotify-play-playlist spotify-play-track
                writeStrictShellScriptBin settings i3statusconf;
  };

  termiteDot = pkgs.callPackage ./termite { inherit libdot settings; };
  gnupgDot = pkgs.callPackage ./gnupg { inherit libdot settings; };
  fishDot = with scripts; pkgs.callPackage ./fish { inherit libdot settings edi; };
  alacrittyDot = pkgs.callPackage ./alacritty { inherit libdot settings; };
  sshDot = pkgs.callPackage ./ssh { inherit libdot settings; };
  gitDot = with scripts; pkgs.callPackage ./git { inherit libdot settings edi; };
  pulseDot = pkgs.callPackage ./pulse { inherit libdot settings; };
  gsimplecalDot = pkgs.callPackage ./gsimplecal { inherit libdot settings; };
  mimeappsDot = pkgs.callPackage ./mimeapps { inherit libdot settings; };
  yubicoDot = pkgs.callPackage ./yubico { inherit libdot settings; };
  xresourcesDot = pkgs.callPackage ./xresources { inherit libdot settings; };
  tmuxDot = pkgs.callPackage ./tmux { inherit libdot settings; };
  mbsyncDot = pkgs.callPackage ./mbsync { inherit libdot settings; };
  imapnotifyDot = with scripts; pkgs.callPackage ./imapnotify { inherit libdot settings emacs-run; };
  waybarDot = pkgs.callPackage ./waybar { inherit libdot settings; };
  spotifydDot = pkgs.callPackage ./spotifyd { inherit libdot settings; };
  direnvDot = pkgs.callPackage ./direnv { inherit libdot settings; };
  systemd = pkgs.callPackage ./systemd { inherit libdot settings; };
  makoDot = pkgs.callPackage ./mako { inherit libdot settings; };
  starshipDot = pkgs.callPackage ./starship { inherit libdot settings; };

  dotfiles = [ gnupgDot fishDot swaydot makoDot
               alacrittyDot sshDot gitDot starshipDot
               pulseDot gsimplecalDot tmuxDot
               mimeappsDot yubicoDot termiteDot
               xresourcesDot mbsyncDot imapnotifyDot
               waybarDot spotifydDot direnvDot systemd
             ];

  home = builtins.getEnv "HOME";

  home-update = with libdot; with pkgs; pkgs.writeShellScriptBin "home-update" ''
    #!${stdenv.shell}
    set -e
    export PATH=${makeSearchPath "bin" [ coreutils findutils nix sway gnused ]}:$PATH
    previous_generation="$(ls $NIX_USER_PROFILE_DIR/ | sort | tail -n2 | head -1)"
    previous_generation_path="$NIX_USER_PROFILE_DIR/$previous_generation"
    current_generation_path="$HOME/.nix-profile"
    root=''${1:-${home}}
    latestVersion=$(nix-store --query --hash $(readlink ${home}/.nix-profile/dotfiles))
    currentVersion=""
    if [ -e $root/.dotfiles_version ]; then
      currentVersion=$(cat $root/.dotfiles_version)
    fi
    if [ "$currentVersion" = "$latestVersion" ]; then
      echo "Up-to-date already"
      exit 0
    else
      echo "Updating to latest version '$latestVersion' from '$currentVersion'"
    fi
    shopt -s dotglob
    mkdir -p $root
    chmod u+rwx $root
    echo "Stopping and disabling systemd units from previous generation '$(echo "$previous_generation" | awk -F'-' '{print $2}')'..."
    for file in "$previous_generation_path"/dotfiles/.config/systemd/user/*; do
      if [ ! -d "$file" ]; then
        if grep -q "\[Install\]" "$file" >/dev/null; then
          echo "Stopping service $(basename "$file")..."
          systemctl --user stop "$(basename "$file")" || true
          echo "Disabling service $(basename "$file")..."
          systemctl --user disable "$(basename "$file")" || true
        else
          echo "No install section in \"$file\", not disabling unit"
          echo "Stopping service $(basename "$file")..."
          systemctl --user stop "$(basename "$file")" || true
        fi
      fi
    done
    if [ -e $root/.dotfiles_manifest ]; then
      for file in $(cat $root/.dotfiles_manifest); do
        if [ ! -e ${home}/.nix-profile/dotfiles/$file ]; then
          echo "removing deleted dotfile '$file'"
          rm -f $root/$file
        fi
      done
      rm -f $root/.dotfiles_manifest
    fi
    for file in ${home}/.nix-profile/dotfiles/*; do
      if [ "$(basename $file)" = "set-permissions.sh" ]; then
         continue
      fi
      cmd="cp --no-preserve=ownership,mode -rf $file $root/"
      echo $cmd
      $cmd
    done
    if [ -e ${home}/.nix-profile/dconf/dconf.conf ]; then
      echo "Updating dconf..."
      cat ${home}/.nix-profile/dconf/dconf.conf | ${pkgs.gnome3.dconf}/bin/dconf load /
    else
      echo "No dconf found, skipping"
    fi
    if [ -d ${home}/.nix-profile/terminfo ]; then
      echo "Updating terminfo database..."
      rm -rf ${home}/.terminfo
      for file in ${home}/.nix-profile/terminfo/*; do
        ${pkgs.ncurses}/bin/tic -x -o ~/.terminfo $file
      done
    fi
    echo Ensuring permissions on dotfiles...
    pushd $root
    ${stdenv.shell} -x ${home}/.nix-profile/dotfiles/set-permissions.sh
    popd
    find ${home}/.nix-profile/dotfiles/ -type f | grep -v "set-permissions.sh" | sed  "s|${home}/.nix-profile/dotfiles/||g" > $root/.dotfiles_manifest
    echo $latestVersion > $root/.dotfiles_version
    systemctl --user daemon-reload
    for file in ${home}/.config/systemd/user/*; do
      if [ ! -d "$file" ]; then
        if grep -q "\[Install\]" "$file" >/dev/null; then
          echo "Enabling and starting service $(basename "$file")..."
          systemctl --user enable "$(basename "$file")" || true
          systemctl --user start "$(basename "$file")"
        else
          echo "No install section in \"$file\", not enabling unit"
          echo "Starting service $(basename "$file")..."
          systemctl --user start "$(basename "$file")"
        fi
      fi
    done
    #swaymsg reload || true
    #${pkgs.killall}/bin/killall -s HUP $(${pkgs.coreutils}/bin/basename $SHELL) 2>/dev/null || true
  '';

in

stdenv.mkDerivation rec {
  name = "dotfiles";
  phases = [ "installPhase" ];
  src = ./.;
  installPhase = with pkgs; with libdot; ''
    export PATH=${makeSearchPath "bin" [ coreutils findutils nix sway gnused ]}:$PATH
    dotfiles=$out/dotfiles
    dconf=$out/dconf
    terminfo=$out/terminfo
    bin=$out/bin
    install -dm 755 $dotfiles
    install -dm 755 $dconf
    install -dm 755 $terminfo
    install -dm 755 $bin

    pushd $dotfiles
    ${concatStringsSep "\n" dotfiles}
    popd

    ${toShell settings.dconf (name: value:
    ''
      echo "[${name}]" >> $dconf/dconf.conf
      ${if isAttrs value then
          toShell value (name: value:
          ''
            echo "${name}='${value}'" >> $dconf/dconf.conf
          ''
          )
        else
          value
      }
    ''
    )}

    ${toShell settings.terminfo (name: value:
    ''
      echo "${value}" >> $terminfo/${name}.terminfo
    ''
    )}

    ${toShell scripts (name: value:
    ''
      echo "installing script ${name} to $bin"
      cp -r ${value}/bin/${name} $bin/
    ''
    )}

    cp ${home-update}/bin/home-update $bin/home-update
  '';
}
