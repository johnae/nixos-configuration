{ stdenv, lib, rustPlatform, sources }:

with rustPlatform;
buildRustPackage rec {
  pname = sources.tmux-thumbs.repo;
  version = sources.tmux-thumbs.rev;

  src = sources.tmux-thumbs;

  cargoSha256 = "0pir2miq04049scnb9wjd2fnz1vzs04igj4gvzrarkcicpm615vi";

  outputs = [ "out" ];

  meta = with stdenv.lib; {
    inherit (sources.persway) description homepage;
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
