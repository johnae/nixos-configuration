{ stdenv, fetchurl }:

let metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in stdenv.mkDerivation rec {
  inherit (metadata) version;
  name = "rust-analyzer-${version}";
  src = fetchurl { inherit (metadata) hash url; };
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/ra_lsp_server
    chmod +x $out/bin/ra_lsp_server
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
