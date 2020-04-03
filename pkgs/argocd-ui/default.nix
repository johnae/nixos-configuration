{ stdenv, git, cacert, nodejs-10_x, yarn, argocd }:
let
  nodejs = nodejs-10_x;
  yarnOverridden = yarn.override { inherit nodejs; };
  src = "${argocd.src}/ui";
in
stdenv.mkDerivation rec {
  name = "argocd-ui";
  inherit src;
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "0vnf5w5qi5n6c6fckdnz4h5piissi60g4gam0x07ly0fxwvij9vn";
  buildInputs = [ git cacert nodejs yarn ];
  buildPhase = ''
    export HOME=$NIX_BUILD_TOP/fake_home
    yarn install --frozen-lockfile --no-progress --non-interactive
    sed -i 's|/usr/bin/env node|${nodejs}/bin/node|g' ./node_modules/.bin/webpack
    rm -rf dist && ./node_modules/.bin/webpack --config ./src/app/webpack.config.js
  '';
  installPhase = ''
    mkdir -p $out
    cp -r dist $out/shared
  '';
}
