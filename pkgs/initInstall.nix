{stdenv, sops, git, btrfs-progs, writeStrictShellScriptBin, ...}:

writeStrictShellScriptBin "init-install" ''
  PATH=${sops}/bin:${git}/bin:${btrfs-progs}/bin''${PATH:+:}$PATH
  export PATH
  cd ~
  for vol in Sync Downloads; do
    if [ ! -e "$vol" ]; then
      echo Creating "$vol" btrfs subvolume
      btrfs sub create "$vol"
    else
      echo "$vol" already exists
    fi
  done

  mkdir -p Development Photos Pictures Mount Documents Videos
  if [ ! -e Development/nixos-configuration ]; then
    git clone --recursive git@github.com:johnae/nixos-configuration Development/nixos-configuration
  else
    echo nixos-configuration already exists at Development/nixos-configuration
  fi

  if [ ! -e "$PASSWORD_STORE_DIR" ]; then
    echo Cloning password store to "$PASSWORD_STORE_DIR"
    git clone git@github.com:johnae/passwords "$PASSWORD_STORE_DIR"
  else
    echo Password store "$PASSWORD_STORE_DIR" already present
  fi

  sudo mkdir -p /root/.ssh
  sudo chmod 0700 /root/.ssh
  sops -d Development/nixos-configuration/metadata/backup_id_rsa | \
          sudo tee /root/.ssh/backup_id_rsa
  sudo chmod 0600 /root/.ssh/backup_id_rsa
''