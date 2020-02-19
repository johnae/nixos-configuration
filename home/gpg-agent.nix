{ pkgs, config, lib, options }:
let
  gpgImport = pkgs.writeShellScript "gpg-import" ''
    ${pkgs.gnupg}/bin/gpg --import ${../public.key.gpg}
    ${pkgs.gnupg}/bin/gpg --import-ownertrust ${../gpg.ownertrust.txt}
  '';
in
{
  services.my-gpg-agent = rec {
    enable = true;
    defaultCacheTtl = 1800;
    defaultCacheTtlSsh = 1800;
    maxCacheTtl = defaultCacheTtl * 8;
    maxCacheTtlSsh = defaultCacheTtlSsh * 8;
    enableSshSupport = true;
    enableScDaemon = true;
    pinentryFlavor = "gnome3";
    extraConfig = ''
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';
    networkNamespace = "private";
  };

  systemd.user.services.gpg-key-import = {
    Unit = {
      Description = "GnuPG public key auto import with trust";
      After = "my-gpg-agent.service";
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${gpgImport}";
    };

    Install = {
      WantedBy = [ "my-gpg-agent.service" ];
    };
  };
}
