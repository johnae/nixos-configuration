{stdenv, lib, libdot, writeText, pkgs, ...}:

with libdot;
with lib;

let

  direnvrc = with pkgs; writeText "direnvrc" ''
    eval "`declare -f use_nix | sed '1s/.*/_&/'`"

    use_nix() {
      if type lorri &>/dev/null; then
        echo "direnv: using lorri from PATH ($(type -p lorri))"
        eval "$(lorri direnv)"
      else
        _use_nix
      fi
    }
  '';

in

  {
    __toString = self: ''
      ${copy { path = direnvrc; to = ".direnvrc"; }}
    '';
  }