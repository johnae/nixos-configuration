{...}:

let
  home-manager = with builtins;
    let
       hmeta = fromJSON (readFile ./home-manager.json);
    in
       fetchGit {
         url = "https://github.com/${hmeta.owner}/${hmeta.repo}";
         inherit (hmeta) rev;
         ref = "master";
       };
in

{
  imports = [
    ./services.nix
    (import "${home-manager}/nixos")
  ];
}