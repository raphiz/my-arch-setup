#!/usr/bin/env bash
set -eu

PASSWORD=$1
PARTITION_ROOT_UUID=$2
HOSTNAME=$3

echo "generate & set locale"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Set the timezone"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime

echo "Setting hostname"
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1   localhost
::1         localhost
127.0.0.1   $HOSTNAME.local $HOSTNAME" > /etc/hosts

echo "Define new root password"
echo "$PASSWORD
$PASSWORD" | passwd

# Setup boot loader
# I don't know why, but this exits with 1 :/
bootctl --path=/.efi install || true

sed -i 's/HOOKS=(.*)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard shutdown)/g' /etc/mkinitcpio.conf

echo "title   Arch Linux
version EDGE
linux	/installs/EDGE/vmlinuz-linux
initrd  /installs/EDGE/intel-ucode.img
initrd	/installs/EDGE/initramfs-linux.img
options cryptdevice=UUID=$PARTITION_ROOT_UUID:crypted root=/dev/mapper/crypted rootflags=subvol=@snapshots/EDGE rw quiet" >  /.efi/loader/entries/EDGE.conf

echo "timeout 3
default EDGE
editor no" > /.efi/loader/loader.conf

echo "Generate initial ramdisk environment"
mkinitcpio -p linux


echo "Creating EDGE snapshot"
btrfs subvolume snapshot / /.snapshots/EDGE
sed -i 's#subvol=/@,subvol=@#subvol=/@snapshots/EDGE,subvol=@snapshots/EDGE#g' /.snapshots/EDGE/etc/fstab

echo "Creating STABLE and MINIMAL snapshot based on EDGE"
btrfs subvolume snapshot / /.snapshots/STABLE/
btrfs subvolume snapshot / /.snapshots/MINIMAL/
sed -i 's/EDGE/STABLE/g' /.snapshots/STABLE/etc/fstab
sed -i 's/EDGE/MINIMAL/g' /.snapshots/MINIMAL/etc/fstab
cp /.efi/loader/entries/EDGE.conf /.efi/loader/entries/STABLE.conf
cp /.efi/loader/entries/EDGE.conf /.efi/loader/entries/MINMAL.conf
sed -i 's/EDGE/STABLE/g' /.efi/loader/entries/STABLE.conf
sed -i 's/EDGE/MINIMAL/g' /.efi/loader/entries/MINMAL.conf
cp -r /.efi/installs/EDGE /.efi/installs/STABLE
cp -r /.efi/installs/EDGE /.efi/installs/MINIMAL

echo "Creating subvolume for home snapshots"
btrfs subvolume create /home/.snapshots

