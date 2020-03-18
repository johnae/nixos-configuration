{stdenv, fetchurl, makeWrapper}:

let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
  stdenv.mkDerivation rec {
      version = metadata.version;
      name = "buildkite-agent-${version}";
      src = fetchurl metadata.${stdenv.system};
      buildInputs = [ makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/share
        cp ../buildkite-agent $out/share/
        makeWrapper $out/share/buildkite-agent $out/bin/buildkite-agent \
          --set BUILDKITE_HOOKS_PATH ${./hooks}
      '';
      buildPhase = "true";
  }