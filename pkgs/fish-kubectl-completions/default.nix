{fetchFromGitHub, ...}:
fetchFromGitHub ( with builtins; fromJSON (readFile ./metadata.json) )