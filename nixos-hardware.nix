with builtins;
let nhmeta = fromJSON (readFile ./nixos-hardware.json);
in fetchGit {
  url = "https://github.com/${nhmeta.owner}/${nhmeta.repo}";
  inherit (nhmeta) rev;
  ref = "master";
}
