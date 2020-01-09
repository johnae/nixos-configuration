let
  metadata = builtins.fromJSON (builtins.readFile ./nixpkgs-metadata.json);
  nixpkgs = builtins.fetchTarball metadata;
in
  import nixpkgs { system = "x86_64-linux"; }
#  import "${nixpkgs}/nixos" {
#    configuration = {
#      imports = [
#        ./configuration.nix
#      ];
#    };
#
#    system = "x86_64-linux";
#  }