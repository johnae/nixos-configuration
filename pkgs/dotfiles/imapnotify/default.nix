{
  stdenv,
  lib,
  libdot,
  emacs-run,
  writeText,
  settings,
  ...
}:

let
  config = settings.mbsync;
  configFiles = map (x:
    rec {
       name = "imapnotify.${x.imapaccount.imapaccount}.js";
       path = writeText name ''
         var child_process = require('child_process');
         
         function getStdout(cmd) {
           var stdout = child_process.execSync(cmd);
           return stdout.toString().trim();
         }
         
         exports.host = "${x.imapaccount.host}";
         exports.port = 993;
         exports.tls = true;
         exports.tlsOptions = { "rejectUnauthorized": false };
         exports.username = "${x.imapaccount.user}";
         exports.password = getStdout("${x.imapaccount.passcmd}");
         exports.onNewMail = "${emacs-run}/bin/emacs-run -e '(mu4e-update-mail-and-index t)'";
         exports.boxes = [ "INBOX" ];
       '';
    }
  ) config.accounts;

in

  {
    dirmode = "0700";
    filemode = "0600";
    __toString = self: ''
      ${
        lib.concatMapStrings (x:
          libdot.copy {
            path = x.path;
            to = ".config/${x.name}";
            mode = self.filemode;
          }) configFiles
      }
    '';
  }
