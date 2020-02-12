# { pkgs, fetchFromGitHub, fetchgit, fetchurl, glibc, pandoc, isync, imapnotify, git, wl-clipboard, mu, writeText, ... }:
{ emacsPackages, fetchgit, writeText, mu, emacsWithPackagesFromUsePackage, pkgs
, ... }:

let
  jl-encrypt = emacsPackages.melpaBuild {
    pname = "jl-encrypt";
    version = "20190618";

    src = fetchgit {
      url = "https://gitlab.com/lechten/defaultencrypt.git";
      rev = "ba07acc8e9fd692534c39c7cdad0a19dc0d897d9";
      sha256 = "1ln7h1syx7yi7bqvirv90mk4rvwxg4zm1wvfcvhfh64s3hqrbfgl";
    };

    recipe = writeText "jl-encrypt-recipe" ''
      (jl-encrypt :fetcher git
                  :url "https://gitlab.com/lechten/defaultencrypt.git"
                  :files (:defaults))
    '';
  };

  config = pkgs.callPackage ./config.nix { };

in emacsWithPackagesFromUsePackage {
  config = builtins.readFile config.emacsConfig;
  package = pkgs.emacsGit-nox;
  extraEmacsPackages = epkgs: [ jl-encrypt ];
}
