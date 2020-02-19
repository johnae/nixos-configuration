{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.my-gpg-agent;

  netns = conf: if conf.networkNamespace == null then "" else "/run/wrappers/bin/netns-exec ${conf.networkNamespace} ";

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
  ''
  + optionalString cfg.enableSshSupport
    "${netns cfg}${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null";
in
{

  options = {
    services.my-gpg-agent = {
      enable = mkEnableOption "GnuPG private key agent";

      defaultCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry is valid to the given number of
          seconds.
        '';
      };

      defaultCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry used for SSH keys is valid to the
          given number of seconds.
        '';
      };

      maxCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry is valid to n seconds. After this
          time a cache entry will be expired even if it has been accessed
          recently or has been set using gpg-preset-passphrase. The default is
          2 hours (7200 seconds).
        '';
      };

      maxCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry used for SSH keys is valid to n
          seconds. After this time a cache entry will be expired even if it has
          been accessed recently or has been set using gpg-preset-passphrase.
          The default is 2 hours (7200 seconds).
        '';
      };

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use the GnuPG key agent for SSH keys.
        '';
      };

      sshKeys = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Which GPG keys (by keygrip) to expose as SSH keys.
        '';
      };

      enableExtraSocket = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable extra socket of the GnuPG key agent (useful for GPG
          Agent forwarding).
        '';
      };

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to produce verbose output.
        '';
      };

      grabKeyboardAndMouse = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Tell the pinentry to grab the keyboard and mouse. This
          option should in general be used to avoid X-sniffing
          attacks. When disabled, this option passes
          <option>no-grab</option> setting to gpg-agent.
        '';
      };

      enableScDaemon = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Make use of the scdaemon tool. This option has the effect of
          enabling the ability to do smartcard operations. When
          disabled, this option passes
          <option>disable-scdaemon</option> setting to gpg-agent.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          allow-emacs-pinentry
          allow-loopback-pinentry
        '';
        description = ''
          Extra configuration lines to append to the gpg-agent
          configuration file.
        '';
      };

      pinentryFlavor = mkOption {
        type = types.nullOr (types.enum pkgs.pinentry.flavors);
        example = "gnome3";
        default = "gtk2";
        description = ''
          Which pinentry interface to use. If not
          <literal>null</literal>, it sets
          <option>pinentry-program</option> in
          <filename>gpg-agent.conf</filename>. Beware that
          <literal>pinentry-gnome3</literal> may not work on non-Gnome
          systems. You can fix it by adding the following to your
          system configuration:
          <programlisting language="nix">
          services.dbus.packages = [ pkgs.gcr ];
          </programlisting>
          For this reason, the default is <literal>gtk2</literal> for
          now.
        '';
      };

      networkNamespace = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "private";
        description = ''
          Which network namespace to launch into. If not
          <literal>null</literal>, it will launch gpg-agent
          into the specified network namespace.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file.".gnupg/gpg-agent.conf".text = concatStringsSep "\n" (
        optional (cfg.enableSshSupport) "enable-ssh-support"
        ++ optional (!cfg.grabKeyboardAndMouse) "no-grab"
        ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
        ++ optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
        ++ optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
        ++ optional (cfg.maxCacheTtl != null)
          "max-cache-ttl ${toString cfg.maxCacheTtl}"
        ++ optional (cfg.maxCacheTtlSsh != null)
          "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
        ++ optional (cfg.pinentryFlavor != null)
          "pinentry-program ${pkgs.pinentry.${cfg.pinentryFlavor}}/bin/pinentry"
        ++ [ cfg.extraConfig ]
      );

      home.sessionVariables =
        optionalAttrs cfg.enableSshSupport {
          SSH_AUTH_SOCK = "$(${netns cfg}${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)";
        };

      programs.bash.initExtra = gpgInitStr;
      programs.zsh.initExtra = gpgInitStr;
    }

    (mkIf (cfg.sshKeys != null) {
      # Trailing newlines are important
      home.file.".gnupg/sshcontrol".text = concatMapStrings (s: "${s}\n") cfg.sshKeys;
    }
    )

    # The systemd units below are direct translations of the
    # descriptions in the
    #
    #   ${pkgs.gnupg}/share/doc/gnupg/examples/systemd-user
    #
    # directory.
    {
      systemd.user.services.my-gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
          Requires = "my-gpg-agent.socket";
          After = "my-gpg-agent.socket";
          # This is a socket-activated service:
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${netns cfg}${pkgs.gnupg}/bin/gpg-agent --supervised"
          + optionalString cfg.verbose " --verbose";
          ExecReload = "${netns cfg}${pkgs.gnupg}/bin/gpgconf --reload gpg-agent";
        };
      };

      systemd.user.sockets.my-gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
        };

        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent";
          FileDescriptorName = "std";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    }

    (mkIf cfg.enableSshSupport {
      systemd.user.sockets.my-gpg-agent-ssh = {
        Unit = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent.ssh";
          FileDescriptorName = "ssh";
          Service = "my-gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    }
    )

    (mkIf cfg.enableExtraSocket {
      systemd.user.sockets.my-gpg-agent-extra = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache (restricted)";
          Documentation = "man:gpg-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent.extra";
          FileDescriptorName = "extra";
          Service = "my-gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    }
    )
  ]
  );
}
