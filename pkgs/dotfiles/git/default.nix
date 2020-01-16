{stdenv, libdot, writeText, settings, edi, ...}:

with settings.git;

let
  config = writeText "gitconfig" ''
    [user]
      name = ${fullName}
      email = ${email}
      signingkey = ${signingKey}
    [core]
      editor = ${edi}/bin/edi -t
    [push]
      # only push current branch to tracking branch
      default = upstream
    [merge]
      tool = fugitive
      conflictstyle = diff3
      prompt = false
    [diff]
      tool = vimdiff
      renames = copy
      renamelimit = 0
    [difftool]
      prompt = false
    [color]
      ui = auto
      branch = auto
      status = auto
      diff = auto
      interactive = auto
      grep = auto
      pager = true
      decorate = auto
      showbranch = auto
    [mergetool "vimdiff"]
      path = nvim
      cmd = nvim -d "$BASE" "$LOCAL" "$REMOTE" "$MERGED"
    [mergetool "fugitive"]
      cmd = nvim -f -c \"Gvdiff\" \"$MERGED\"
    [difftool "vimdiff"]
      path = nvim
    [commit]
      gpgsign = true
    [pull]
      rebase = true
    [rebase]
      autoStash = true
    [url "git@github.com:"]
      insteadOf = https://github.com/
    [credential "https://github.com"]
      username = johnae
      helper = pass "web/github.com/johnae"
    [credential "https://repo.insane.se"]
      username = johnae
      helper = pass "web/repo.insane.se/johnae"
  '';

in

  {
    __toString = self: ''
      ${libdot.copy { path = config; to = ".gitconfig"; }}
    '';
  }