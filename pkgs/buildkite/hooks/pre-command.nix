with import <insanepkgs> { };
with pkgs;
with insane-lib;
mkShell {
  buildInputs = [ strict-bash docker google-cloud-sdk ];
}