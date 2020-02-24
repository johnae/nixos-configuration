{ stdenv, fetchurl }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  inherit (metadata) version;
  name = "rust-analyzer-${version}";
  src = fetchurl { inherit (metadata) hash url; };
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/rust-analyzer
    chmod +x $out/bin/rust-analyzer
    ln -s $out/bin/rust-analyzer $out/bin/ra_lsp_server
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
