{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2020-01-19";
  name = "font-jet-brains-mono-${version}";

  srcs = [
    ./ttf/JetBrainsMono-Bold.ttf
    ./ttf/JetBrainsMono-Regular.ttf
    ./ttf/JetBrainsMono-Italic.ttf
    ./ttf/JetBrainsMono-Medium.ttf
    ./ttf/JetBrainsMono-Bold-Italic.ttf
    ./ttf/JetBrainsMono-Medium-Italic.ttf
    ./ttf/JetBrainsMono-ExtraBold.ttf
    ./ttf/JetBrainsMono-ExtraBold-Italic.ttf
  ];

  phases = [ "unpackPhase" "installPhase" ];

  sourceRoot = "./";

  unpackCmd = ''
    ttfName=$(basename $(stripHash $curSrc))
    echo "ttfname: $ttfName"
    cp $curSrc ./$ttfName
  '';

  installPhase = ''
    mkdir -p $out/share/fonts/jet-brains-mono
    cp *.ttf $out/share/fonts/jet-brains-mono
  '';

  meta = {
    description = "JetBrains Mono Font";
    homepage = https://www.jetbrains.com/lp/mono;
    platforms = stdenv.lib.platforms.all;
    maintainers = [];
  };
}
