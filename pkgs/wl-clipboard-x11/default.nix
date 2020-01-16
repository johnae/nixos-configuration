{ stdenv, coreutils, lib, shellcheck, bash, wl-clipboard }:

with lib;

let

  setToStringSep = sep: x: fun: concatStringsSep sep (mapAttrsToList fun x);

  substituteInPlace = file: substitutions: ''
    substituteInPlace ${file} \
      ${setToStringSep " "
                       substitutions
                       (name: value: '' --subst-var-by ${name} "${value}"'' )}
  '';

  mkStrictShellScript =
    { name
    , src
    , substitutions ? {}
    }: stdenv.mkDerivation {
      inherit name;
      buildCommand = ''
        install -v -D -m755 ${src} $out/bin/${name}
        ${substituteInPlace "$out/bin/${name}" substitutions}

        if S=$(grep -E '@[a-zA-Z0-9-]+@' < $out/bin/${name}); then
          WHAT=$(echo "$S" | sed 's|.*\(@.*@\).*|\1|g')
          cat<<ERR

          ${name}:
             '$WHAT'
               ^ this doesn't look right, forgotten substitution?

        ERR
          exit 1
        fi

        ## check the syntax
        ${stdenv.shell} -n $out/bin/${name}

        ## shellcheck
        ${shellcheck}/bin/shellcheck -x -e SC1117 -s bash -f tty $out/bin/${name}
      '';
    };

    wl-copy = "${wl-clipboard}/bin/wl-copy";
    wl-paste = "${wl-clipboard}/bin/wl-paste";

in

  mkStrictShellScript {
    name = "xclip";
    src = ./xclip.sh;
    substitutions = {
      inherit bash wl-copy wl-paste;
    };
  }

#stdenv.mkDerivation rec {
#  name = "wl-clipboard-x11";
#  version = "2019-04-24";
#
#  src = ./.;
#
#  preConfigure = ''
#    echo "Fixing cat path..."
#    ${gnused}/bin/sed -i"" 's|\(/bin/cat\)|${coreutils}\1|g' src/wl-paste.c
#  '';
#
#  nativeBuildInputs = [
#    meson ninja pkgconfig git
#  ];
#  buildInputs = [
#    wayland wayland-protocols
#  ];
#
#  enableParallelBuilding = true;
#
#  meta = with stdenv.lib; {
#    description = "Hacky clipboard manager for Wayland";
#    homepage    = https://github.com/bugaevc/wl-clipboard;
#    license     = licenses.gpl3;
#    platforms   = platforms.linux;
#    maintainers = with maintainers; [ primeos ]; # Trying to keep it up-to-date.
#  };
#}