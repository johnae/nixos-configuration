let
  meta = builtins.fromJSON (builtins.readFile ./mozilla.json);
in
import (
  builtins.fetchGit {
    url = "https://github.com/${meta.owner}/${meta.repo}";
    inherit (meta) rev;
    ref = "master";
  }
)
