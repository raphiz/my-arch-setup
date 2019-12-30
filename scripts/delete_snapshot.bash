#!/usr/bin/env bash
set -eu

# USAGE: ./delete_snapshot.bash SNAPSHOT_NAME
# 
# example: ./delete_snapshot.bash 2019-12-30
# This would delete the snapshot called 2019-12-30

# User must be root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root, use sudo $0 instead"
   exit 1
fi

if [ $# -ne 1 ]; then
    echo "USAGE: ./$0 SNAPSHOT_NAME" >&2
    exit 1;
fi

SNAPSHOT_NAME=$1

echo "INFO: Will delete snapshot $SNAPSHOT_NAME."

read -p "Are you sure? (Enter yes in uppercase to continue) " -r

if [ ! "$REPLY" == "YES" ]; then
    echo "Aborting" >&2
    exit 1
fi

CURRENTLY_MOUNTED_SNAPSHOT=$(findmnt -n --target=/ -o OPTIONS | sed -E 's/.*subvol=\/@snapshots\/([^,]+*).*/\1/')

if [ "$CURRENTLY_MOUNTED_SNAPSHOT" == "$SNAPSHOT_NAME" ]; then
    echo "ERROR: You cannot delete a snapshot that is currently in use!" >&2
    exit 1
fi

if [ -d "/.snapshots/$SNAPSHOT_NAME/" ]; then
    echo "INFO: Deleting filesystem..."
    btrfs subvolume delete "/.snapshots/$SNAPSHOT_NAME/"
else
    echo "WARN: Filesystem snapshot does not exist" >&2
fi

if [ -f "/.efi/loader/entries/$SNAPSHOT_NAME.conf" ]; then
    echo "INFO: Deleting boot loader entry..."
    rm "/.efi/loader/entries/$SNAPSHOT_NAME.conf"
else
    echo "WARN: boot loader entry does not exist" >&2
fi

if [ -d "/.efi/installs/$SNAPSHOT_NAME" ]; then
    echo "INFO: Deleting kernel..."
    rm -Rf "/.efi/installs/$SNAPSHOT_NAME"
else
    echo "WARN: kernel does not exist" >&2
fi


# echo "INFO: Copying boot loader entry..."
# cp "/.efi/loader/entries/$SNAPSHOT_SOURCE.conf" "/.efi/loader/entries/$NEW_SNAPSHOT_NAME.conf"
# sed -i "s/$SNAPSHOT_SOURCE/$NEW_SNAPSHOT_NAME/g" "/.efi/loader/entries/$NEW_SNAPSHOT_NAME.conf"

# echo "INFO: Copying kernel..."
# cp -r "/.efi/installs/$SNAPSHOT_SOURCE" "/.efi/installs/$NEW_SNAPSHOT_NAME"
