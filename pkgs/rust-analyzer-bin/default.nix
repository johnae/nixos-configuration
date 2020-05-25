{ stdenv, sources }:
stdenv.mkDerivation rec {
  inherit (sources.rust-analyzer) version;
  name = "rust-analyzer-${version}";
  src = sources.rust-analyzer;
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/rust-analyzer
    chmod +x $out/bin/rust-analyzer
    ln -s $out/bin/rust-analyzer $out/bin/ra_lsp_server
  '';
  fixupPhase = ''
    chmod 755 $out/bin/rust-analyzer
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
             $out/bin/rust-analyzer
  '';

  unpackPhase = "true";
  buildPhase = "true";

  meta = with stdenv.lib; {
    description = "Pre-built rust-analyzer";
    longDescription = ''
      An experimental Rust compiler front-end for IDEs
    '';
    homepage = "https://github.com/rust-analyzer/rust-analyzer";
    platforms = platforms.linux;
  };
}
