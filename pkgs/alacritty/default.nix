{ stdenv
, lib
, fetchFromGitHub
, rustPlatform
, cmake
, makeWrapper
, ncurses
, expat
, pkgconfig
, freetype
, fontconfig
, libX11
, gzip
, libXcursor
, libXxf86vm
, libXi
, libXrandr
, libGL
, python3
, wayland
, libxkbcommon
, libxcb
, sources
}:

with rustPlatform;
let
  rpathLibs = [
    expat
    freetype
    fontconfig
    libX11
    libXcursor
    libXxf86vm
    libXrandr
    libGL
    libXi
  ] ++ lib.optionals stdenv.isLinux [ wayland libxkbcommon libxcb ];

in
buildRustPackage rec {
  pname = sources.alacritty.repo;
  version = sources.alacritty.rev;
  doCheck = false;

  src = sources.alacritty;
  cargoSha256 = "1f8s0mjr5s4jq7154m7ibkwaym6xcz2fzwgpf8ykbgs4cgcfzkxs";

  nativeBuildInputs = [ cmake makeWrapper pkgconfig ncurses gzip python3 ];

  buildInputs = rpathLibs;

  outputs = [ "out" "terminfo" ];

  postBuild = lib.optionalString stdenv.isDarwin "make app";

  installPhase = ''
    runHook preInstall

    install -D target/release/alacritty $out/bin/alacritty

  '' + (
    if stdenv.isDarwin
    then ''
      mkdir $out/Applications
      cp -r target/release/osx/Alacritty.app $out/Applications/Alacritty.app
    '' else ''
      install -D extra/linux/Alacritty.desktop -t $out/share/applications/
      install -D extra/logo/alacritty-term.svg $out/share/icons/hicolor/scalable/apps/Alacritty.svg
      patchelf --set-rpath "${
        stdenv.lib.makeLibraryPath rpathLibs
      }" $out/bin/alacritty
    ''
  ) + ''

    install -D extra/completions/_alacritty -t "$out/share/zsh/site-functions/"
    install -D extra/completions/alacritty.bash -t "$out/etc/bash_completion.d/"
    install -D extra/completions/alacritty.fish -t "$out/share/fish/vendor_completions.d/"

    install -dm 755 "$out/share/man/man1"
    gzip -c extra/alacritty.man > "$out/share/man/man1/alacritty.1.gz"

    install -dm 755 "$terminfo/share/terminfo/a/"
    tic -x -o "$terminfo/share/terminfo" extra/alacritty.info
    mkdir -p $out/nix-support
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages

    runHook postInstall
  '';

  dontPatchELF = true;

  meta = with stdenv.lib; {
    inherit (sources.alacritty) description homepage;
    license = with licenses; [ asl20 ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}
