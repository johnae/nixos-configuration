{ stdenv, rustPlatform, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.netns-exec.repo;
  version = sources.netns-exec.rev;

  src = sources.netns-exec;
  cargoSha256 = "1sdb2li5hcll6x0ip15rigq8kkd9s22sfbz3278y9jdf0fcsm5in";

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
