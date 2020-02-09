{ pkgs, fetchFromGitHub, fetchgit, fetchurl, glibc, pandoc, isync, imapnotify, git, wl-clipboard, mu, writeText, ... }:

let

  emacsConfig = pkgs.runCommand "README.emacs-conf.org" {
    buildInputs = with pkgs; [ emacs ];
  } ''
     install -D ${./README.org} $out/share/emacs/site-lisp/README.org
     substituteInPlace "$out/share/emacs/site-lisp/README.org" \
                       --subst-var-by MUSE_LOAD_PATH \
                       "${mu}/share/emacs/site-lisp/mu4e" \
                       --subst-var-by MBSYNC \
                       "${isync}/bin/mbsync" \
                       --subst-var-by PANDOC \
                       "${pandoc}/bin/pandoc" \
                       --subst-var-by IMAPNOTIFY \
                       "${imapnotify}/bin/imapnotify" \
                       --subst-var-by WLCOPY \
                       "${wl-clipboard}/bin/wl-copy" \
                       --subst-var-by WLPASTE \
                       "${wl-clipboard}/bin/wl-paste"
     cd $out/share/emacs/site-lisp
     emacs --batch --quick -l ob-tangle --eval "(org-babel-tangle-file \"README.org\")"
     emacs -batch -f batch-byte-compile **/*.el
  '';

  ## because later versions broke lots of evil packages
  undo-tree = emacsPackages.elpaBuild {
    pname = "undo-tree";
    ename = "undo-tree";
    version = "0.6.5";
    src = fetchurl {
      url = "https://elpa.gnu.org/packages/undo-tree-0.6.5.el";
      sha256 = "0bs97xyxwfkjvzax9llg0zsng0vyndnrxj5d2n5mmynaqcn89d37";
    };
    packageRequires = [];
    meta = {
      homepage = "https://elpa.gnu.org/packages/undo-tree.html";
    };
  };

  emacsPackages =
    pkgs.emacsPackagesNg.overrideScope'
    (self: super: {
      inherit undo-tree;
      inherit (self.melpaPackages)
        evil flycheck-haskell haskell-mode
        use-package;
    });

  compileEmacsFiles = pkgs.callPackage ./builder.nix;
  fetchFromEmacsWiki = pkgs.callPackage ({ fetchurl, name, sha256 }:
    fetchurl {
      inherit sha256;
      url = "https://www.emacswiki.org/emacs/download/" + name;
    });

  compileEmacsWikiFile = { name, sha256, buildInputs ? [], patches ? [] }:
    compileEmacsFiles {
      inherit name buildInputs patches;
      src = fetchFromEmacsWiki { inherit name sha256; };
  };

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

  ## use a nord-theme that works with 24-bit terminals
  nord-theme = emacsPackages.melpaBuild {
    pname = "nord-theme";
    version = "20200112";
    src = fetchFromGitHub {
      owner = "arcticicestudio";
      repo = "nord-emacs";
      rev = "0f5295f99005a200191ce7b660e56cd0510cf710";
      sha256 = "096f8cik4jz89bvkifwp3gm9iraqrd75ljy2q9js724v7yj88711";
    };

    recipe = writeText "nord-theme-recipe" ''
      (nord-theme :repo "nord-theme/nord-theme.el" :fetcher github
                 :files (:defaults))
    '';
  };

  lsp-mode = emacsPackages.melpaBuild {
    pname = "lsp-mode";
    version = "20200209";
    src = fetchFromGitHub {
      owner = "emacs-lsp";
      repo = "lsp-mode";
      rev = "51dd86473edfeaef067bfc9f9063c7d72dbf8831";
      sha256 = "07ghy1arbqlc8y71n8x8jhxhskh2ilva6n3fqpcbzjwpqv8n6rvf";
    };

    recipe = writeText "lsp-mode-recipe" ''
      (lsp-mode :repo "emacs-lsp/lsp-mode" :fetcher github
                     :files ("lsp-mode.el"))
    '';
  };

  ## use up-to-date nix-mode
  nix-mode = emacsPackages.melpaBuild {
    pname = "nix-mode";
    version = "20191003";

    src = fetchFromGitHub {
      owner = "NixOS";
      repo = "nix-mode";
      rev = "5b5961780f3b1c1b62453d2087f775298980f10d";
      sha256 = "0lyf9vp6sivy321z8l8a2yf99kj5g15p6ly3f8gkyaf6dcq3jgnc";
    };

    recipe = writeText "nix-mode-recipe" ''
      (nix-mode :repo "NixOS/nix-mode" :fetcher github
                :files (:defaults (:exclude "nix-mode-mmm.el")))
    '';
  };

  prescientSource = fetchFromGitHub {
    owner  = "raxod502";
    repo   = "prescient.el";
    rev    = "2f01b640e3a487718dbc481d14406005c0212ed9";
    sha256 = "1wqk1g8fjpcbpiz32k7arnisncd4n9zs84dn3qn9y8ggjzldqy91";
  };

  prescient = emacsPackages.melpaBuild {
    pname   = "prescient";
    version = "3.3.0";
    src     = prescientSource;

    recipe = writeText "prescient-recipe" ''
      (prescient :repo "raxod502/prescient.el" :fetcher github
                 :files ("prescient.el"))
    '';
  };

  ivy-prescient = emacsPackages.melpaBuild {
    pname   = "ivy-prescient";
    version = "3.3.0";
    src     = prescientSource;
    packageRequires = [ prescient ];

    recipe = writeText "ivy-prescient-recipe" ''
      (ivy-prescient :repo "raxod502/prescient.el" :fetcher github
                     :files ("ivy-prescient.el"))
    '';
  };

  company-prescient = emacsPackages.melpaBuild {
    pname   = "company-prescient";
    version = "3.3.0";
    src     = prescientSource;
    packageRequires = [ prescient ];

    recipe = writeText "company-prescient-recipe" ''
      (company-prescient  :repo "raxod502/prescient.el" :fetcher github
                         :files ("company-prescient.el"))
    '';
  };

  lua-mode = emacsPackages.melpaBuild {
    pname = "lua-mode";
    version = "20190113";

    src = fetchFromGitHub {
      owner = "immerrr";
      repo = "lua-mode";
      rev = "95c64bb5634035630e8c59d10d4a1d1003265743";
      sha256 = "0i38fkq50g1z1lvvjm1k4qdzjizv8kqm3j3523s9s72vbmal7jy4";
    };

    recipe = writeText "lua-mode-recipe" ''
      (lua-mode :repo "immerrr/lua-mode" :fetcher github
                :files ("lua-mode.el"))
    '';
  };

in

  emacsPackages.emacsWithPackages (epkgs: with epkgs; [
    use-package

    # Interface
    bind-key
    company
    ivy counsel swiper
    projectile  # project management
    counsel-projectile
    ripgrep  # search
    which-key  # display keybindings after incomplete command

    # sorting and filtering
    prescient
    ivy-prescient
    company-prescient

    jl-encrypt

    prodigy # manage external services

    visual-fill-column

    #benchmark-init

    # Themes
    diminish
    all-the-icons
    powerline
    telephone-line
    spaceline
    spaceline-all-the-icons
    zerodark-theme
    eink-theme

    # Delimiters
    smartparens
    linum-relative
    fringe-helper

    highlight-numbers

    memoize

    # Evil
    avy
    evil
    evil-org
    evil-magit
    evil-indent-textobject
    evil-nerd-commenter
    evil-surround
    evil-collection

    alert
    mu4e-alert

    undo-tree
    frames-only-mode
    zoom-window

    # Git
    # git-auto-commit-mode
    # git-timemachine
    magit
    diff-hl

    swift-mode

    # Helpers
    direnv
    kubernetes-tramp
    docker-tramp
    counsel-tramp

    # Language support
    moonscript
    lua-mode
    json-mode
    yaml-mode
    markdown-mode
    groovy-mode
    alchemist # elixir
    terraform-mode
    company-terraform
    elvish-mode
    jsonnet-mode

    company-quickhelp
    column-enforce-mode

    # Go
    go-mode
    company-go
    go-guru
    go-eldoc
    flycheck-gometalinter
    ob-go

    flycheck-checkbashisms

    auto-compile
    flycheck
    flycheck-popup-tip
    flycheck-pos-tip

    string-inflection

    lsp-mode
    lsp-ui
    company-lsp

    racket-mode
    esh-autosuggest
    fish-completion # fish completion in eshell

    markdown-mode
    yaml-mode
    web-mode
    pos-tip
    dockerfile-mode
    js2-mode
    tide
    prettier-js

    # Haskell
    haskell-mode
    flycheck-haskell
    company-ghci  # provide completions from inferior ghci

    # Org
    org
    org-ref
    org-bullets
    org-tree-slide # presentations

    # polymode allows more than 1 major mode in a buffer basically
    polymode
    poly-markdown
    poly-org

    # Rust
    rust-mode cargo flycheck-rust racer

    # Nix
    # nix-buffer nixos-options company-nixos-options nix-sandbox
    nixos-options company-nixos-options

    # config file
    emacsConfig
  ] ++

  # Custom packages
  [ nix-mode prescient ivy-prescient company-prescient nord-theme ]
)
