{stdenv, shellcheck, lib, writeTextFile, coreutils, ...}:

with lib;

{

  setToStringSep = sep: x: fun: concatStringsSep sep (mapAttrsToList fun x);

  writeStrictShellScript = name: text:
    writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!${stdenv.shell}
        set -euo pipefail
        ${text}
      '';
      checkPhase = ''
        ${stdenv.shell} -n $out
        ${shellcheck}/bin/shellcheck -s bash -f tty $out
      '';
    };

  writeStrictShellScriptBin = name: text:
    writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = ''
        #!${stdenv.shell}
        set -euo pipefail
        ${text}
      '';
      checkPhase = ''
        ${stdenv.shell} -n $out/bin/${name}
        ${shellcheck}/bin/shellcheck -s bash -f tty $out/bin/${name}
      '';
    };

  mkdir = {path, mode ? "0755"}: ''
        ${coreutils}/bin/echo "mkdir $PWD/${path} with mode ${mode}"
        ${coreutils}/bin/mkdir -p ${path}
        ${coreutils}/bin/echo ${coreutils}/bin/chmod ${mode} ${path} >> set-permissions.sh
  '';

  copy = {path, to, mode ? "0644"}: ''
        ${coreutils}/bin/echo "copy ${path} to $PWD/${to} with mode ${mode}"
        ${coreutils}/bin/cat ${path} > ${to}
        dir=$(${coreutils}/bin/dirname ${to})
        name=$(${coreutils}/bin/basename ${to})
        ${coreutils}/bin/echo ${coreutils}/bin/chmod ${mode} ${to} >> set-permissions.sh
  '';

}
