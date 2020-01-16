{
  stdenv,
  lib,
  libdot,
  writeText,
  pinentry_gnome,
  coreutils,
  keyservers ? [ "hkp://jirk5u4osbsr34t5.onion" "hkp://keys.gnupg.net" ],
  ...
}:

let
  gpgConfig = writeText "gpg.conf" ''
    auto-key-locate keyserver
    keyserver hkps://hkps.pool.sks-keyservers.net
    #keyserver-options no-honor-keyserver-url
    #keyserver-options ca-cert-file=/etc/sks-keyservers.netCA.pem
    #keyserver-options no-honor-keyserver-url
    #keyserver-options debug
    #keyserver-options verbose
    personal-cipher-preferences AES256 AES192 AES CAST5
    personal-digest-preferences SHA512 SHA384 SHA256 SHA224
    default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
    cert-digest-algo SHA512
    s2k-cipher-algo AES256
    s2k-digest-algo SHA512
    charset utf-8
    fixed-list-mode
    no-comments
    no-emit-version
    keyid-format 0xlong
    list-options show-uid-validity
    verify-options show-uid-validity
    with-fingerprint
    use-agent
    require-cross-certification
  '';

  gpgAgentConfig = writeText "gpg-agent.conf" ''
    enable-ssh-support
    default-cache-ttl 1800
    max-cache-ttl 10800
    pinentry-program ${pinentry_gnome}/bin/pinentry-gnome3
  '';

  dirMngrConfig = writeText "dirmngr.conf" ''
    # dirmngr.conf - Options for Dirmngr
    # Written in 2015 by The GnuPG Project <https://gnupg.org>
    #
    # To the extent possible under law, the authors have dedicated all
    # copyright and related and neighboring rights to this file to the
    # public domain worldwide.  This file is distributed without any
    # warranty.  You should have received a copy of the CC0 Public Domain
    # Dedication along with this file. If not, see
    # <http://creativecommons.org/publicdomain/zero/1.0/>.
    #
    #
    # Unless you specify which option file to use (with the command line
    # option "--options filename"), the file ~/.gnupg/dirmngr.conf is used
    # by dirmngr.  The file can contain any long options which are valid
    # for Dirmngr.  If the first non white space character of a line is a
    # '#', the line is ignored.  Empty lines are also ignored.  See the
    # dirmngr man page or the manual for a list of options.
    #

    # --keyserver URI
    #
    # GPG can send and receive keys to and from a keyserver.  These
    # servers can be HKP, Email, or LDAP (if GnuPG is built with LDAP
    # support).
    #
    # Example HKP keyservers:
    #      hkp://keys.gnupg.net
    #
    # Example HKP keyserver using a Tor OnionBalance service
    #      hkp://jirk5u4osbsr34t5.onion
    #
    # Example HKPS keyservers (see --hkp-cacert below):
    #       hkps://hkps.pool.sks-keyservers.net
    #
    # Example LDAP keyservers:
    #      ldap://pgp.surfnet.nl:11370
    #
    # Regular URL syntax applies, and you can set an alternate port
    # through the usual method:
    #      hkp://keyserver.example.net:22742
    #
    # Most users just set the name and type of their preferred keyserver.
    # Note that most servers (with the notable exception of
    # ldap://keyserver.pgp.com) synchronize changes with each other.  Note
    # also that a single server name may actually point to multiple
    # servers via DNS round-robin.  hkp://keys.gnupg.net is an example of
    # such a "server", which spreads the load over a number of physical
    # servers.
    #
    # If exactly two keyservers are configured and only one is a Tor hidden
    # service, Dirmngr selects the keyserver to use depending on whether
    # Tor is locally running or not (on a per session base).

    ${lib.concatMapStrings (x: "keyserver " + x + "\n") keyservers}

    # --hkp-cacert FILENAME
    #
    # For the "hkps" scheme (keyserver access over TLS), Dirmngr needs to
    # know the root certificates for verification of the TLS certificates
    # used for the connection.  Enter the full name of a file with the
    # root certificates here.  If that file is in PEM format a ".pem"
    # suffix is expected.  This option may be given multiple times to add
    # more root certificates.  Tilde expansion is supported.

    #hkp-cacert /path/to/CA/sks-keyservers.netCA.pem
  '';

in

  {
    dirmode = "0700";
    filemode = "0600";
    __toString = self: ''
      echo "Ensuring .gnupg directory..."
      ${libdot.mkdir { path = ".gnupg"; mode = self.dirmode; }}
      ${libdot.copy { path = gpgConfig; to = ".gnupg/gpg.conf"; mode = self.filemode; }}
      ${libdot.copy { path = gpgAgentConfig; to = ".gnupg/gpg-agent.conf"; mode = self.filemode; }}
      ${libdot.copy { path = dirMngrConfig; to = ".gnupg/dirmngr.conf"; mode = self.filemode; }}
    '';
  }