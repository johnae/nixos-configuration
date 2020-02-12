{ pkgs, config, lib, options }:

let

in

{

  xdg.configFile."fish/functions/gcloud_sdk_argcomplete.fish".source = "${pkgs.google-cloud-sdk-fish-completion}/functions/gcloud_sdk_argcomplete.fish";
  xdg.configFile."fish/completions/gcloud.fish".source = "${pkgs.google-cloud-sdk-fish-completion}/completions/gcloud.fish";
  xdg.configFile."fish/completions/gsutil.fish".source = "${pkgs.google-cloud-sdk-fish-completion}/completions/gsutil.fish";
  xdg.configFile."fish/completions/kubectl.fish".source = "${pkgs.fish-kubectl-completions}/completions/kubectl.fish";

  programs.fish = {
    enable = true;
    shellAbbrs = {
      cat = "bat";
      g = "git";
    };
    shellAliases = {
      k8s-run = "${pkgs.kubectl}/bin/kubectl run tmp-shell --generator=run-pod/v1 --rm -i --tty --image=nixpkgs/nix-unstable --restart=Never --attach -- nix-shell -p bashInteractive --run bash";
    };
    shellInit = with pkgs; ''
      source ${skim}/share/skim/key-bindings.fish
      set fish_greeting
      fish_vi_key_bindings ^ /dev/null

      function fish_user_key_bindings
        skim_key_bindings

        function skim-jump-to-project-widget -d "Show list of projects"
          set -q SK_TMUX_HEIGHT; or set SK_TMUX_HEIGHT 40%
          begin
            set -lx SK_DEFAULT_OPTS "--height $SK_TMUX_HEIGHT $SK_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $SK_CTRL_R_OPTS +m"
            set -lx dir (${project-select}/bin/project-select ~/Development ~/.config)
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
          set proj (${google-cloud-sdk}/bin/gcloud projects list | tail -n +2 | ${gawk}/bin/awk '{print $1}' | ${skim}/bin/sk)
          gcloud config set project $proj
        end
        bind \cw gcloud-project-select
        if bind -M insert > /dev/null 2>&1
          bind -M insert \cw gcloud-project-select
        end
      end
    '';
    loginShellInit = ''
      if test "$DISPLAY" = ""; and test (tty) = /dev/tty1; and test "$XDG_SESSION_TYPE" = "tty"
        export GDK_BACKEND=wayland
        export MOZ_ENABLE_WAYLAND=1
        export XCURSOR_THEME=default
        exec sway
      end
    '';
  };
}