# Installation

Note that this is a specific setup to suit my personal needs.
If you are looking for a general-purpose arch Linux installation, have a look at the official [Installation Guide](https://wiki.archlinux.org/index.php/installation_guide).

## Preparation

- Download the latest image from the [Download page](https://www.archlinux.org/download/).
- Write the image on a USB device:

```bash
# Check Image
sha1sum archlinux-2018.04.01-x86_64.iso

# Check Signature
gpg --keyserver-options auto-key-retrieve --verify archlinux-2018.04.01-x86_64.iso.sig

# Write image on boot media (as root)
dd bs=4M if=archlinux-2018.04.01-x86_64.iso of=/dev/sdX oflag=sync
```

- Download this repository and copy its contents onto another USB device
  - Feel free to choose another medium. The only requirement is that you can access this directory during the installation
- Boot from the USB device

## Base System Installation

DISCLAIMER: Note that this installation script was tested with the Arch Linux installation image from 2021-06-01. Manual intervention for newer images might be required.

```bash
# Verify boot mode is EFI
ls /sys/firmware/efi/efivars

# Setup internet connection, for example, using iwctl for WiFi:
iwctl
> device list
> station wlan0 scan
> station wlan0 get-networks
> station wlan0 connect <SSID>
> station wlan0 show
> exit

# HIDPI: use a bigger font
pacman -S terminus-font
setfont ter-u32b

# Optional: Wipe your disk
cryptsetup open --type plain -d /dev/urandom /dev/DISKNAME to_be_wiped
dd bs=4M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
cryptsetup close to_be_wiped

# Mount the installation data, eg. using a USB device:
mkdir /tmp/installation
mount /dev/sdXY /tmp/installation

# Start the installation
/tmp/installation/path-to-repo/install/install.bash # Additional parameters required, see below
```

The installation script takes the following parameters:

- `DISK_NAME`: The name of the disk to use, e.g. `/dev/nvme0n1` or `/dev/sda`.
- `PARTITION_PREFIX`: If a partition prefix is required, eg. for `/dev/nvme0n1p1` the prefix is `p`, whereas for `/dev/sda1` the prefix is `''`.
- `BLOCKSIZE`: The physical sector size. Use `lsblk -o NAME,PHY-SeC` to check what block size your disk uses.
- `HOSTNAME`: The desired hostname to use for this installation. This value should match the name used in the `hosts` directory.

During the installation, you will be prompted for a root password, to confirm the creation of the new partitions and to provide a passphrase for the root partition. After the installation is completed, reboot into the newly installed system.

## Ansible Setup

After the installation of the base system (and a reboot), it's time to install the actual system configuration managed by ansible.

```bash
# Setup internet connection, for example, using iwctl
systemctl enable iwd
systemctl start iwd
iwctl

# Mount the installation data, eg. using a USB device:
mkdir /tmp/installation
mount /dev/sdXY /tmp/installation

# Copy the config to /tmp
cp -r /tmp/installation/path-to-repo/. /config

# Launch ansible setup
/config/run.bash
```

## Restore personal Data

After a fresh installation, the user home must be restored. I personally use [restic]((https://restic.readthedocs.io/en) and restore all files manually to clean up the user home at the same time.

```bash
restic -r /srv/restic-repo restore latest --target /tmp/restic-restore

# Manually copy the files that shall be restored...
cp -r /tmp/restic-restore/files/to/restore ~/to/destination
```
