{ stdenv, lib, buildGoModule, fetchFromGitHub, packr }:
let
  metadata = lib.importJSON ./metadata.json;
in
buildGoModule rec {
  pname = "argocd";
  commit = metadata.rev;
  version = "1.4.2";

  src = fetchFromGitHub metadata;

  modSha256 = "0gpg25dw8hmpjwq24w8163vs8zi83hx9dx85yfcx6q5izvixk3i2";

  nativeBuildInputs = [ packr ];

  patches = [ ./use-go-module.patch ];

  CGO_ENABLED = 0;

  buildFlagsArray = ''
    -ldflags=
     -X github.com/argoproj/argo-cd/common.version=${version}
     -X github.com/argoproj/argo-cd/common.buildDate=unknown
     -X github.com/argoproj/argo-cd/common.gitCommit=${commit}
     -X github.com/argoproj/argo-cd/common.gitTreeState=clean
  '';

  # run packr to embed assets
  preBuild = ''
    packr
  '';

  meta = with stdenv.lib; {
    description = "Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo";
    license = licenses.asl20;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
