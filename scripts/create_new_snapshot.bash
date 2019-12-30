#!/usr/bin/env bash
set -eu

# USAGE: ./create_new_snapshot.bash NEW_SNAPSHOT_NAME SNAPSHOT_SOURCE
# 
# example: ./create_new_snapshot.bash 2019-12-30 EDGE
# This would create a new snapshot based on the EDGE snapshot

# User must be root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root, use sudo $0 instead"
   exit 1
fi

if [ $# -ne 2 ]; then
    echo "USAGE: ./$0 NEW_SNAPSHOT_NAME SNAPSHOT_SOURCE" >&2
    exit 1
fi


NEW_SNAPSHOT_NAME=$1
SNAPSHOT_SOURCE=$2

if [ -d "/.snapshots/$NEW_SNAPSHOT_NAME/" ]; then
    echo "ERROR: $NEW_SNAPSHOT_NAME does already exist! Aborting!" >&2
    exit 1
fi

echo "INFO: Creating a copy of $SNAPSHOT_SOURCE called: $NEW_SNAPSHOT_NAME"

echo "INFO: Copying filesystem..."
btrfs subvolume snapshot "/.snapshots/$SNAPSHOT_SOURCE/" "/.snapshots/$NEW_SNAPSHOT_NAME/"
sed -i "s/$SNAPSHOT_SOURCE/$NEW_SNAPSHOT_NAME/g" "/.snapshots/$NEW_SNAPSHOT_NAME/etc/fstab"

echo "INFO: Copying boot loader entry..."
cp "/.efi/loader/entries/$SNAPSHOT_SOURCE.conf" "/.efi/loader/entries/$NEW_SNAPSHOT_NAME.conf"
sed -i "s/$SNAPSHOT_SOURCE/$NEW_SNAPSHOT_NAME/g" "/.efi/loader/entries/$NEW_SNAPSHOT_NAME.conf"

echo "INFO: Copying kernel..."
cp -r "/.efi/installs/$SNAPSHOT_SOURCE" "/.efi/installs/$NEW_SNAPSHOT_NAME"
