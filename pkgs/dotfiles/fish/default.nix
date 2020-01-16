{stdenv, libdot, writeText, starship, skim, kubectx, kubectl, fd, lsd, edi, fetchFromGitHub, ...}:

let

  config = writeText "config.fish" ''

     if test "$TERM" = "xterm-termite"
       set -x TERM termite
     end

     function i
       nix-env -iA nixos.$argv
     end

     function s
       nix-env -qaP ".*$argv.*"
     end

     function k8s-run
       kubectl run tmp-shell --generator=run-pod/v1 --rm -i --tty --image=nixpkgs/nix-unstable --restart=Never --attach -- nix-shell -p bashInteractive --run bash
     end

     complete -c home -w git

     if not set -q abbrs_initialized
       set -U abbrs_initialized
       echo -n Setup abbreviations...

       abbr cat bat
       abbr hr 'nix-env -iA nixos.home; and home-update'

       abbr g 'git'
       abbr ga 'git add'
       abbr gb 'git branch'
       abbr gbl 'git blame'
       abbr gc 'git commit -m'
       abbr gco 'git checkout'
       abbr gcp 'git cherry-pick'
       abbr gd 'git diff'
       abbr gf 'git fetch'
       abbr gl 'git log'
       abbr gm 'git merge'
       abbr gp 'git push'
       abbr gpl 'git pull'
       abbr gr 'git remote'
       abbr gs 'git status'
       abbr gst 'git stash'

       echo 'Done'
     end

     # emacs socket
     set -x EMACS_SERVER_FILE /run/user/1337/emacs1337/server

     if test "$DISPLAY" = ""; and test (tty) = /dev/tty1; and test "$XDG_SESSION_TYPE" = "tty"
        exec start-sway
     end

     if test "$TERM" = "dumb"
        function fish_title; end
     end

     set fish_color_error ff8a00

     # c0 to c4 progress from dark to bright
     # ce is the error colour
     set -g c0 (set_color 005284)
     set -g c1 (set_color 0075cd)
     set -g c2 (set_color 009eff)
     set -g c3 (set_color 6dc7ff)
     set -g c4 (set_color ffffff)
     set -g ce (set_color $fish_color_error)

     # remove greeting
     set fish_greeting

     # aliases (in fish these are actually translated to functions)
     ## manage home
     alias home="env GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git"
     alias untracked="git ls-files --others --exclude-standard"
     alias ls="${lsd}/bin/lsd --group-dirs first"

     function home_commit_packages
       cd ~
       for change in (home diff --name-only .config/nixpkgs/packages | xargs -r -I{} dirname {} | sort -u); home add $change; home commit -m "Updated "(echo $change | sed 's|\.config/nixpkgs/packages/||g'); end
     end

     fish_vi_key_bindings ^ /dev/null

     function clear_direnv_cache
       echo "Clearing direnv cache"
       fd --type d -I -H '\.direnv$' ~/Development/ | xargs rm -rf
       date +%s > ~/.direnv_cache_cleared
     end

     ## auto clear after 20 hours
     ## if not test -e ~/.direnv_cache_cleared; or test (math (date +%s) " - " (cat ~/.direnv_cache_cleared)) -ge 72000
     ##    clear_direnv_cache
     ## end

     function reload_fish_config --on-signal HUP
       eval exec $SHELL
     end

     eval (${starship}/bin/starship init fish)
  '';

  skimConfig = writeText "fish_user_key_bindings.fish" ''
     source ${skim}/share/skim/key-bindings.fish
     function fish_user_key_bindings
       skim_key_bindings

       function skim-jump-to-project-widget -d "Show list of projects"
         set -q SK_TMUX_HEIGHT; or set SK_TMUX_HEIGHT 40%
         begin
           set -lx SK_DEFAULT_OPTS "--height $SK_TMUX_HEIGHT $SK_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $SK_CTRL_R_OPTS +m"
           set -lx dir (project-select ~/Development ~/.config)
           if [ "$dir" != "" ]
             cd $dir
             set -lx file (${fd}/bin/fd -H -E "\.git" . | "${skim}"/bin/sk)
             if [ "$file" != "" ]
               ${edi}/bin/edi "$file"
             end
           end
         end
         commandline -f repaint
       end
       bind \cg skim-jump-to-project-widget
       if bind -M insert > /dev/null 2>&1
         bind -M insert \cg skim-jump-to-project-widget
       end

       function skim-jump-to-file-widget -d "Show list of file to open in editor"
         set -q SK_TMUX_HEIGHT; or set SK_TMUX_HEIGHT 40%
         begin
           set -lx SK_DEFAULT_OPTS "--height $SK_TMUX_HEIGHT $SK_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $SK_CTRL_R_OPTS +m"
           set -lx file (${fd}/bin/fd -H -E "\.git" . | "${skim}"/bin/sk)
           if [ "$file" != "" ]
             ${edi}/bin/edi "$file"
           end
         end
         commandline -f repaint
       end
       bind \cf skim-jump-to-project-widget
       if bind -M insert > /dev/null 2>&1
         bind -M insert \cf skim-jump-to-file-widget
       end

       function kubectx-select -d "Select kubernetes cluster"
         ${kubectx}/bin/kubectx
       end
       bind \ck kubectx-select
       if bind -M insert > /dev/null 2>&1
         bind -M insert \ck kubectx-select
       end

       function kubens-select -d "Select kubernetes namespace"
         ${kubectx}/bin/kubens
       end
       bind \cn kubectx-select
       if bind -M insert > /dev/null 2>&1
         bind -M insert \cn kubens-select
       end

       function gcloud-project-select -d "Select gcloud project"
         if command -sq gcloud
         set proj (gcloud projects list | tail -n +2 | awk '{print $1}' | "${skim}"/bin/sk)
           gcloud config set project $proj
         else
           echo Missing command gcloud
         end
       end
       bind \cw gcloud-project-select
       if bind -M insert > /dev/null 2>&1
         bind -M insert \cw gcloud-project-select
       end


     end
   '';

   gcloudSrc = fetchFromGitHub {
     owner = "Doctusoft";
     repo = "google-cloud-sdk-fish-completion";
     rev = "bc24b0bf7da2addca377d89feece4487ca0b1e9c";
     sha256 = "03zzggi64fhk0yx705h8nbg3a02zch9y49cdvzgnmpi321vz71h4";
   };

   kubectlCompletions = fetchFromGitHub {
     owner = "evanlucas";
     repo = "fish-kubectl-completions";
     rev = "c870a143c5af2ac5a8174173a96e110a7677637f";
     sha256 = "0cn8k6axfrglvy7x3sw63g08cgxfq3z4jqxfxm05558qfc8hfhc2";
   };

in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/fish/functions"; }}
      ${libdot.mkdir { path = ".config/fish/completions"; }}
      ${libdot.copy { path = config; to = ".config/fish/config.fish";  }}
      ${libdot.copy { path = skimConfig; to = ".config/fish/functions/fish_user_key_bindings.fish";  }}
      ${libdot.copy { path = "${gcloudSrc}/functions/gcloud_sdk_argcomplete.fish"; to = ".config/fish/functions/gcloud_sdk_argcomplete.fish";  }}
      ${libdot.copy { path = "${kubectlCompletions}/kubectl.fish"; to = ".config/fish/completions/kubectl.fish"; }}
      ${libdot.copy { path = "${gcloudSrc}/completions/gcloud.fish"; to = ".config/fish/completions/gcloud.fish"; }}
      ${libdot.copy { path = "${gcloudSrc}/completions/gsutil.fish"; to = ".config/fish/completions/gsutil.fish"; }}
    '';
  }
