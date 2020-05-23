{ stdenv, lib, buildGoModule, packr, sources }:
buildGoModule rec {
  pname = "argocd";
  commit = sources.argo-cd.version;
  version = sources.argo-cd.version;

  src = sources.argo-cd;

  modSha256 = "024xsx2ia26p89ql0k7rqsrf55fz6gqaivw4pdzcvk5f4cza8mi5";

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
