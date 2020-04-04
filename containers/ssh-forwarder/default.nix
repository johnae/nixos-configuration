{ stdenv
, writeStrictShellScriptBin
, gnused
, coreutils
, bashInteractive
, mkpasswd
, openssl
, openssh
, dockerTools
, dockerRegistry ? "johnae"
, dockerTag ? "latest"
}:
let
  entrypoint = writeStrictShellScriptBin "entrypoint.sh" ''
    export PATH=${coreutils}/bin:${gnused}/bin:${PATH:+:}$PATH
    mkdir -p /etc
    env > /etc/environment

    username="forwarder"
    password="$(${openssl}/bin/openssl rand -hex 6)"
    hashed_password="$(${mkpasswd}/bin/mkpasswd -m sha-512 "$password")"
    echo Username: "$username"
    echo Password: "$password"
    userhome="/home/forwarder"
    mkdir -p "$userhome"

    cat<<EOF>/etc/passwd
    root:x:0:0:System administrator:/root:/bin/bash
    $username:x:1337:1337:Forwarder:$userhome:/bin/bash
    sshd:x:498:65534:SSH privilege separation user:/var/empty:/bin/nologin
    EOF

    cat<<EOF>/etc/shadow
    $username:$hashed_password:1::::::
    EOF

    if [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
      echo /etc/ssh/ssh_host_rsa_key missing
      exit 1
    fi

    if [ -e /etc/ssh/authorized_keys ]; then
      mkdir -p "$userhome"/.ssh
      chmod 0700 "$userhome"/.ssh
      cp /etc/ssh/authorized_keys "$userhome"/.ssh/authorized_keys
      chmod 0600 "$userhome"/.ssh/authorized_keys
      chown -R 1337:1337 "$userhome"
    fi

    mkdir -p /run /var/empty

    sed -i"" 's|^#AddressFamily.*|AddressFamily inet|g' /etc/ssh/sshd_config

    exec ${openssh}/bin/sshd -e -D -p 22
  '';
in
dockerTools.buildLayeredImage {
  name = "${dockerRegistry}/ssh-forwarder";
  tag = dockerTag;
  contents = [
    bashInteractive
    openssh
    coreutils
  ];

  config = {
    Entrypoint = [ "${entrypoint}/bin/entrypoint.sh" ];
    ExposedPorts = {
      "22/tcp" = { };
    };
    WorkingDir = "/home/forwarder";
  };
}
