#!/usr/bin/env sh

## this script can be used when pxe booting a machine into some
## distro from where you can do an install

scriptdir="$(cd "$(dirname "$0")"; pwd -P)"

address=${1:-}
machine=${2:-}

export NIX_SSHOPTS="-T -o RemoteCommand=none"

ssh "$address" -t -o RemoteCommand=none bash <<'SSH'

echo Preparing machine for installation

mkdir -p /ramdisk

## use a ramdisk for this for security
mount -t tmpfs -o size=32g tmpfs /ramdisk

## writing random bytes would be better but
## it's just too slow - even with /dev/urandom
## since it's all in RAM anyway I believe this
## should be very secure anyway, especially given
## the encryption
fallocate -l 31G /ramdisk/nixstore.img

cryptsetup luksFormat /ramdisk/installdata.img
cryptsetup open /ramdisk/installdata.img installdata
mkfs.btrfs /dev/mapper/installdata

mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/mapper/installdata /srv
btrfs subvolume create /srv/@etcnix
btrfs subvolume create /srv/@secrets
btrfs subvolume create /srv/@nix
umount /srv

mkdir -p /etc/nix /secrets
mkdir -p -m 0755 /nix

mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@nix /dev/mapper/nixstore /nix
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@etcnix /dev/mapper/nixstore /etc/nix
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@secrets /dev/mapper/nixstore /secrets
chown root /nix

echo "build-users-group =" > /etc/nix/nix.conf
curl https://nixos.org/nix/install | sh
. $HOME/.nix-profile/etc/profile.d/nix.sh

nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
nix-channel --update

nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

echo '. $HOME/.nix-profile/etc/profile.d/nix.sh' >> $HOME/.bash_profile

SSH

profile=/nix/var/nix/profiles/system
pathToConfig="$(${build}/bin/build -A machines."$machine")"

nix-copy-closure "$address" "$pathToConfig"
scp "$scriptdir"/install.sh "$address":

ssh "$address" -t -o RemoteCommand=none bash <<SSH
 chmod +x ./install.sh
 ## the install.sh expects this file to contain the path to the closure
 echo "$pathToConfig" > /etc/system-closure-path
 SKIP_INSTALL="$SKIP_INSTALL" DISK_PASSWORD="$DISK_PASSWORD" ADDITIONAL_VOLUMES="$ADDITIONAL_VOLUMES" ./install.sh
SSH