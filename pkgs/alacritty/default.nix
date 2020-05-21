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

  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
buildRustPackage rec {
  pname = metadata.repo;
  version = metadata.rev;
  doCheck = false;

  src = fetchFromGitHub metadata;
  cargoSha256 = "1kpjyl3lyslg4jfy0xjdp0wahy9x6ffs5vrrzb88zf2da7yi3w9d";

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
    description = "GPU-accelerated terminal emulator";
    homepage = "https://github.com/jwilm/alacritty";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ mic92 ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}
