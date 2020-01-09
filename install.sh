#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq

set -euo pipefail

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

## This script bootstraps a nixos install. The assumptions are:
# 1. You want an EFI System Partition (500MB) - so no BIOS support
# 2. You want encrypted root and swap
# 3. You want swap space size to be half of RAM as per modern standards
# 4. You want to use btrfs for everything else and you want to use subvolumes
#    for /, /var and /home
# 5. You want to not care about atime and you want
#    to compress your fs using zstd

## on servers we might want additional btrfs subvolumes
## for use with kubernetes local volume provisioner
ADDITIONAL_VOLUMES="${ADDITIONAL_VOLUMES:-}"
## if we want to format an additional disk where we
## probably want those additional volumes above to go
ADDITIONAL_DISK="${ADDITIONAL_DISK:-}"
## allow giving the disk password as an env var. Not safe yadda yadda.
DISK_PASSWORD="${DISK_PASSWORD:-}"

DEVRANDOM=/dev/urandom

if [ "$(systemd-detect-virt)" = "none" ]; then
  CRYPTKEYFILE="${CRYPTKEYFILE:-/sys/class/dmi/id/product_uuid}"
else
  CRYPTKEYFILE="${CRYPTKEYFILE:-/sys/class/dmi/id/product_version}" ## we're testing here
fi

if [ -n "$DISK_PASSWORD" ]; then
    echo -n "$DISK_PASSWORD" > /disk_password
    CRYPTKEYFILE=/disk_password
fi

DISK=/dev/nvme0n1

if [ ! -b "$DISK" ]; then
    echo "$DISK" is not a block device
    DISK=/dev/sda
fi

if [ ! -b "$DISK" ]; then
    echo "$DISK" is not a block device
    echo Giving up
    exit 1
fi

PARTITION_PREFIX=""
if echo "$DISK" | grep -q "nvme"; then
    PARTITION_PREFIX="p"
fi

echo "Formatting disk '$DISK'"

# clear out the disk completely
wipefs -fa "$DISK"
sgdisk -Z "$DISK"

efi_space=500M # EF00 EFI Partition
luks_key_space=20M # 8300
# set to half amount of RAM
swap_space="$(($(free --giga | tail -n+2 | head -1 | awk '{print $2}') / 2))"G
# special case when there's very little ram
if [ "$swap_space" = "0G" ]; then
    swap_space="1G"
fi
# rest (eg. root) will use the remaining space (btrfs) 8300

# now ensure there's a fresh GPT on there
sgdisk -og "$DISK"

sgdisk -n 0:0:+$efi_space -t 0:ef00 -c 0:"efi" "$DISK" # 1
sgdisk -n 0:0:+$luks_key_space -t 0:8300 -c 0:"cryptkey" "$DISK" # 2
sgdisk -n 0:0:+$swap_space -t 0:8300 -c 0:"swap" "$DISK" # 3
sgdisk -n 0:0:0 -t 0:8300 -c 0:"root" "$DISK" # 4

DISK_EFI_LABEL=boot
DISK_EFI="$DISK$PARTITION_PREFIX"1
ENC_DISK_CRYPTKEY_LABEL=cryptkey
DISK_CRYPTKEY="$DISK$PARTITION_PREFIX"2
DISK_SWAP_LABEL=swap
ENC_DISK_SWAP_LABEL=encrypted_swap
DISK_SWAP="$DISK$PARTITION_PREFIX"3
DISK_ROOT_LABEL=root
ENC_DISK_ROOT_LABEL=encrypted_root
DISK_ROOT="$DISK$PARTITION_PREFIX"4
DISK_EXTRA_LABEL=extra
ENC_DISK_EXTRA_LABEL=encrypted_extra
DISK_EXTRA=

sgdisk -p "$DISK"

# make sure everything knows about the new partition table
partprobe "$DISK"
fdisk -l "$DISK"

if [ -n "$ADDITIONAL_DISK" ]; then
    wipefs -fa "$ADDITIONAL_DISK"
    sgdisk -Z "$ADDITIONAL_DISK"
    sgdisk -og "$ADDITIONAL_DISK"
    sgdisk -n 0:0:0 -t 0:8300 -c 0:"extra" "$ADDITIONAL_DISK" # 1

    DISK_EXTRA="$ADDITIONAL_DISK"1

    sgdisk -p "$ADDITIONAL_DISK"
    partprobe "$ADDITIONAL_DISK"
    fdisk -l "$ADDITIONAL_DISK"
fi

# create a disk for the key used to decrypt the other volumes
# either using password or locked to the uuid of the product hardware (less secure ofc)
echo Formatting cryptkey disk "$DISK_CRYPTKEY", using keyfile "$CRYPTKEYFILE"
cryptsetup luksFormat --label="$ENC_DISK_CRYPTKEY_LABEL" -q --key-file="$CRYPTKEYFILE" "$DISK_CRYPTKEY"
DISK_CRYPTKEY=/dev/disk/by-label/"$ENC_DISK_CRYPTKEY_LABEL"

echo Opening cryptkey disk "$DISK_CRYPTKEY", using keyfile "$CRYPTKEYFILE"
cryptsetup luksOpen --key-file="$CRYPTKEYFILE" "$DISK_CRYPTKEY" "$ENC_DISK_CRYPTKEY_LABEL"

# dump random data into what will be our key
echo Writing random data to /dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL"
dd if=$DEVRANDOM of=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" bs=1024 count=14000 || true

# create encrypted swap partition
echo Creating encrypted swap
cryptsetup luksFormat --label="$ENC_DISK_SWAP_LABEL" -q --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_SWAP"

# create the encrypted root partition
echo Creating encrypted root
cryptsetup luksFormat --label="$ENC_DISK_ROOT_LABEL" -q --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_ROOT"

# open those crypt volumes now
echo Opening encrypted swap using keyfile
cryptsetup luksOpen --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_SWAP" "$ENC_DISK_SWAP_LABEL"
mkswap -L "$DISK_SWAP_LABEL" /dev/mapper/"$ENC_DISK_SWAP_LABEL"

echo Opening encrypted root using keyfile
cryptsetup luksOpen --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_ROOT" "$ENC_DISK_ROOT_LABEL"

echo Creating btrfs filesystem on /dev/mapper/"$DISK_ROOT_LABEL"
mkfs.btrfs -L "$DISK_ROOT_LABEL" /dev/mapper/"$ENC_DISK_ROOT_LABEL"

# and create the efi boot partition
echo Creating vfat disk at "$DISK_EFI"
mkfs.vfat -n "$DISK_EFI_LABEL" "$DISK_EFI"

partprobe /dev/mapper/"$ENC_DISK_SWAP_LABEL" ## in case partprobe failed (it might sometimes, but will likely succeed for the given device here)

# enable swap on the decrypted swap device
echo Enabling swap on "/dev/disk/by-label/$DISK_SWAP_LABEL"
swapon /dev/disk/by-label/"$DISK_SWAP_LABEL"

partprobe /dev/mapper/"$ENC_DISK_ROOT_LABEL" ## ditto above for swap

# mount the decrypted cryptroot to /mnt (btrfs)
echo Mounting root fs from "/dev/disk/by-label/$DISK_ROOT_LABEL" to /mnt
mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/disk/by-label/"$DISK_ROOT_LABEL" /mnt

# now create btrfs subvolumes we're interested in having
echo Creating btrfs subvolumes at /mnt
cd /mnt
btrfs sub create @ ## root
mkdir -p "@/boot" "@/home" "@/var"
btrfs sub create @home
btrfs sub create @var

if [ -n "$ADDITIONAL_VOLUMES" ]; then
  echo Creating additional btrfs subvolumes

  if [ -n "$DISK_EXTRA" ] && [ -e "$DISK_EXTRA" ]; then

      echo Creating encrypted fs on additional disk "$DISK_EXTRA"
      cryptsetup luksFormat --label="$ENC_DISK_EXTRA_LABEL" -q --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_EXTRA"

      echo Opening "$DISK_EXTRA" encrypted fs at /dev/mapper/cryptxtra
      cryptsetup luksOpen --key-file=/dev/mapper/"$ENC_DISK_CRYPTKEY_LABEL" "$DISK_EXTRA" "$ENC_DISK_EXTRA_LABEL"

      echo Creating btrfs filesystem on /dev/mapper/"$ENC_DISK_EXTRA_LABEL"
      mkfs.btrfs -L "$DISK_EXTRA_LABEL" /dev/mapper/"$ENC_DISK_EXTRA_LABEL"

      partprobe /dev/mapper/"$ENC_DISK_EXTRA_LABEL"

      echo Mounting extra fs from "/dev/disk/by-label/$DISK_EXTRA_LABEL" to @/mnt/disks
      mount -o rw,noatime,compress=zstd,ssd,space_cache /dev/disk/by-label/"$DISK_EXTRA_LABEL" @/mnt/disks
      cd @/mnt/disks
      for i in $(seq 1 20); do btrfs sub create "@local-disk-$i"; done
      for i in $(seq 1 20); do
          btrfs sub create "@local-disk-nocow-$i"
          chattr +C "@local-disk-nocow-$i"
      done
      cd /mnt

      umount @/mnt/disks
  else
      for i in $(seq 1 20); do btrfs sub create "@local-disk-$i"; done
      for i in $(seq 1 20); do
          btrfs sub create "@local-disk-nocow-$i"
          chattr +C "@local-disk-nocow-$i"
      done
  fi
  cd /mnt
  mkdir -p "@/mnt/disks/cow"
  mkdir -p "@/mnt/disks/nocow"
  for i in $(seq 1 20); do mkdir -p "@/mnt/disks/cow/local-disk-$i"; done
  for i in $(seq 1 20); do mkdir -p "@/mnt/disks/nocow/local-disk-$i"; done

fi
cd "$DIR"
# umount the "real" root and mount those subvolumes in place instead
echo Unmounting /mnt
umount /mnt

echo Devices with uuids
ls -lah /dev/disk/by-uuid/

echo Devices with labels
ls -lah /dev/disk/by-label/

# mount the "root" (@) subvolume to /mnt
echo Mounting root subvolume at /mnt
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@ \
      /dev/disk/by-label/"$DISK_ROOT_LABEL" /mnt
# mount @home subvolume to /mnt/home
echo Mounting home subvolume at /mnt/home
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@home \
      /dev/disk/by-label/"$DISK_ROOT_LABEL" /mnt/home
# mount @var subvolume to /mnt/var
echo Mounting var subvolume at /mnt/var
mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol=@var \
      /dev/disk/by-label/"$DISK_ROOT_LABEL" /mnt/var

if [ -n "$ADDITIONAL_VOLUMES" ]; then
  DISK_LABEL="$DISK_ROOT_LABEL"
  if [ -e "$ADDITIONAL_DISK" ]; then
      DISK_UUID="$DISK_EXTRA_LABEL"
  fi
  echo Mounting additional subvolumes
  for i in $(seq 1 20); do
      mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol="@local-disk-$i" \
        /dev/disk/by-label/"$DISK_LABEL" "/mnt/mnt/disks/cow/local-disk-$i"
      mount -o rw,noatime,compress=zstd,ssd,space_cache,subvol="@local-disk-nocow-$i" \
        /dev/disk/by-label/"$DISK_LABEL" "/mnt/mnt/disks/nocow/local-disk-$i"
  done
fi

# and mount the boot partition
echo Mounting boot partition
mount /dev/disk/by-label/"$DISK_EFI_LABEL" /mnt/boot

#nix copy --from file:///etc/system $(cat /etc/system-closure-path) --option binary-caches "" --no-check-sigs
nixos-install --no-root-passwd --option binary-caches "" --system $(cat /etc/system-closure-path)