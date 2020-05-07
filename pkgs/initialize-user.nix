{ stdenv
, sops
, git
, btrfs-progs
, update-wireguard-keys
, update-wifi-networks
, writeStrictShellScriptBin
, ...
}:

writeStrictShellScriptBin "initialize-user" ''
  PATH=${sops}/bin:${update-wireguard-keys}/bin:${update-wifi-networks}/bin''${PATH:+:}$PATH
  export PATH
  cd ~

  sudo mkdir -p /root/.ssh
  sudo chmod 0700 /root/.ssh
  sops -d Development/nixos-configuration/metadata/backup_id_rsa | \
          sudo tee /root/.ssh/backup_id_rsa >/dev/null
  sudo chmod 0600 /root/.ssh/backup_id_rsa

  update-wifi-networks
  update-wireguard-keys
''
