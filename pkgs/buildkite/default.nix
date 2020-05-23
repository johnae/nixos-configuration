{ stdenv, makeWrapper, sources }:
let
  bksource =
    if stdenv.system == "x86_64-linux" then
      sources.buildkite-linux
    else
      sources.buildkite-darwin;
in
stdenv.mkDerivation rec {
  version = bksource.version;
  name = "buildkite-agent-${version}";
  src = bksource;
  buildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share
    cp ./buildkite-agent $out/share/
    makeWrapper $out/share/buildkite-agent $out/bin/buildkite-agent \
      --set BUILDKITE_HOOKS_PATH ${./hooks}
  '';
  buildPhase = "true";
}
