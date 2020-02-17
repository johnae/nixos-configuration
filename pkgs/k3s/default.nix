{ stdenv, fetchurl }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
in
stdenv.mkDerivation rec {
  inherit (metadata) version;
  name = "k3s-${version}";
  src = fetchurl { inherit (metadata) hash url; };
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/k3s
    chmod +x $out/bin/k3s
  '';

  unpackPhase = "true";
  buildPhase = "true";

  meta = with stdenv.lib; {
    description = "Lightweight Kubernetes";
    longDescription = ''
      Lightweight Kubernetes is a fully certified kubernetes but
      much simpler to deploy and manage while using less resources.
    '';
    homepage = "https://github.com/rancher/k3s";
    platforms = platforms.linux;
  };
}
