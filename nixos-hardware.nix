{
  nixos-hardware = builtins.fetchGit {
     inherit (builtins.fromJSON (
       builtins.readFile ./nixos-hardware.json
     )) url rev;
  };
}