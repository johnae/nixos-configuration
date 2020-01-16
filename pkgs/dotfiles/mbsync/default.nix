{
  stdenv,
  lib,
  libdot,
  writeText,
  settings,
  ...
}:

let
  config = settings.mbsync;
  mbsyncrc = writeText "mbsyncrc" ''
  SyncState *

  ${lib.concatMapStrings (x:
    ''
    IMAPAccount ${x.imapaccount.imapaccount}
    Host ${x.imapaccount.host}
    User ${x.imapaccount.user}
    PassCmd "${x.imapaccount.passcmd}"
    SSLType ${x.imapaccount.ssltype}
    CertificateFile ${x.imapaccount.certificatefile}
    PipelineDepth ${toString x.imapaccount.pipelinedepth}
    Timeout 60

    IMAPStore ${x.imapstore.imapstore}
    Account ${x.imapstore.account}

    MaildirStore ${x.maildirstore.maildirstore}
    Subfolders ${x.maildirstore.subfolders}
    Path ${x.maildirstore.path}
    Inbox ${x.maildirstore.inbox}

    ${lib.concatMapStrings (c:
      libdot.setToStringSep "\n" c (key: value: ''
      ${key} ${value} '') + "\n\n"
    ) x.channels}
    ${lib.concatMapStrings (g:
    ''
    Group ${g.group}
    ${lib.concatMapStrings (cname: ''
    Channel ${cname}
    '') g.channels}
    ''
    ) x.groups}
    ''
  ) config.accounts}
  '';

in

  {
    dirmode = "0700";
    filemode = "0600";
    __toString = self: ''
      ${libdot.copy { path = mbsyncrc; to = ".mbsyncrc"; mode = self.filemode; }}
      echo "Ensuring .mail directories..."
      ${lib.concatMapStrings (x: ''
      ${libdot.mkdir { path = (lib.removePrefix "~/" x.maildirstore.inbox); }}
      '') config.accounts}
    '';
  }
