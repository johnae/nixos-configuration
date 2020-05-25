{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.netns-exec.repo;
  version = sources.netns-exec.rev;

  src = sources.netns-exec;
  cargoSha256 = "1k757mbj9i29191vxb1aqg8yc0v4pdzsfrp97dh5446h9ism9ncj";

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Execute process within Linux network namespace";
    homepage = "https://github.com/johnae/netns-exec";
    license = licenses.mit;
    maintainers = [
      {
        email = "john@insane.se";
        github = "johnae";
        name = "John Axel Eriksson";
      }
    ];
  };
}
