{ exec, ... }: { sops = path: exec [ ./nix-sops.sh path ]; }
