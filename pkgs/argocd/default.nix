{ stdenv, lib, buildGoModule, fetchFromGitHub, packr }:
let
  metadata = lib.importJSON ./metadata.json;
in
buildGoModule rec {
  pname = "argocd";
  commit = metadata.rev;
  version = "git${commit}";

  src = fetchFromGitHub metadata;

  modSha256 = "0b8jikj1v66nn35xy7yhajvcfw09fal3sh6zk5k6lfx60n419q4a";

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
