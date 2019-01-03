#!/usr/bin/env bash
set -eu

if [ $# -ne 4 ]; then
    echo "USAGE: ./install.bash DISK_NAME PARTITION_PREFIX BLOCKSIZE HOSTNAME" >&2
    exit 1;
fi

echo "Checking internet connection"
if ! ping -c 1 archlinux.org > /dev/null
then
    echo "No working connection detected"
    exit 1
fi

DISK_NAME=$1
PARTITION_PREFIX=$2
BLOCKSIZE=$3
HOSTNAME=$4

read -s -p "Enter new root password: " PASSWORD

PARTITION_BOOT="${DISK_NAME}${PARTITION_PREFIX}1"
PARTITION_ROOT="${DISK_NAME}${PARTITION_PREFIX}2"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Using Disk $DISK_NAME"
echo "Using Boot Partition: $PARTITION_BOOT"
echo "Using Root Partition: $PARTITION_ROOT"


echo "Setup time/date"
timedatectl set-timezone Europe/Zurich
timedatectl set-ntp true


echo "Wiping existing disk"
cryptsetup open --type plain -d /dev/urandom "$DISK_NAME" to_be_wiped
dd bs=4M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
cryptsetup close to_be_wiped

echo "Preparing partitions"
gdisk "$DISK_NAME" <<EOF
2 # Create blank GPT
o # Delete partition table
Y # Confirm
n # New EFI partition


+500M
ef00
n # New partition




w # Write to disk and exit
Y
EOF

echo "SetuSetting up boot partition"
mkfs.fat "$PARTITION_BOOT"

echo "Setting up the encrypted LUKS partition"
# The blocksize (512) depends on the actual disk (`lsblk -o NAME,PHY-SeC`) to
cryptsetup -s "$BLOCKSIZE" luksFormat --type luks2 "$PARTITION_ROOT"
cryptsetup luksOpen "$PARTITION_ROOT" crypted
mkfs.btrfs -L arch /dev/mapper/crypted

echo "Creating btrfs subvolumes"
mount /dev/mapper/crypted /mnt
cd /mnt/
btrfs subvolume create @ # root
btrfs subvolume create @pkg # pacman cache
btrfs subvolume create @home # /home
btrfs subvolume create @config # /config (ansible setup)
btrfs subvolume create @snapshots # Hier kommen die snapshots rein

cd /
umount /mnt/

echo "Mounting new root partition"
mount -o subvol=@  /dev/mapper/crypted /mnt

echo "Mounting all subvoolumes"
mkdir -p /mnt/var/cache/pacman/pkg/
mkdir /mnt/home/
mkdir /mnt/config/
mkdir /mnt/.snapshots
mount -o subvol=@pkg /dev/mapper/crypted /mnt/var/cache/pacman/pkg/
mount -o subvol=@home /dev/mapper/crypted /mnt/home
mount -o subvol=@config /dev/mapper/crypted /mnt/config
mount -o subvol=@snapshots /dev/mapper/crypted /mnt/.snapshots

echo "Mounting efi boot partition"
mkdir /mnt/.efi/
mkdir /mnt/boot/
mount "$PARTITION_BOOT" /mnt/.efi
mkdir -p /mnt/.efi/installs/EDGE
mount --bind /mnt/.efi/installs/EDGE /mnt/boot/

echo "Bootstrapping arch distribution"
pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog vim btrfs-progs ansible python-passlib

echo "Generating fstsab"
genfstab -U /mnt >> /mnt/etc/fstab
# Replace /mnt/.efi (binded volume) with /.efi
sed -i 's/\/mnt\/.efi/\/.efi/g' /mnt/etc/fstab

# Get root partition UUID
PARTITION_ROOT_UUID=$(blkid "$PARTITION_ROOT" -s UUID -o value)

echo "Executing chroot"
cp "$SCRIPT_DIR/_install_chroot.bash" /mnt/opt/install_chroot.bash
arch-chroot /mnt /bin/bash <<EOF
bash /opt/install_chroot.bash $PASSWORD $PARTITION_ROOT_UUID $HOSTNAME
rm /opt/install_chroot.bash
exit
EOF

umount -R /mnt

echo "Installation completed. You can now reboot!"
