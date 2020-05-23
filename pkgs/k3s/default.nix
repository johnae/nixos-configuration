{ stdenv, fetchurl, sources }:

stdenv.mkDerivation rec {
  inherit (sources.k3s) version;
  name = "k3s-${version}";

  src = sources.k3s;

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
