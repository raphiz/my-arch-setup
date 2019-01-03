#!/usr/bin/env bash
set -eu

# USAGE: ./_reset.bash SNAPSHOT_TO_RESET SOURCE
# 
# example: ./_reset.bash EDGE MINIMAL
# This would **replace** /.snapshots/EDGE with a newly created snapshot of /.snapshots/MINIMAL

# User must be root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root, use sudo $0 instead"
   exit 1
fi

if [ $# -ne 2 ]; then
    echo "USAGE: ./_reset.bash SNAPSHOT_TO_RESET SOURCE" >&2
    exit 1;
fi

SNAPSHOT_TO_RESET=$1
SNAPSHOT_SOURCE=$2
SNAPSHOTS_DIRECTORY="/.snapshots"
CURRENTLY_MOUNTED_SNAPSHOT=$(findmnt -n --target=/ -o OPTIONS | sed -E 's/.*subvol=\/@snapshots\/([^,]+*).*/\1/')

echo "INFO: Currently, $CURRENTLY_MOUNTED_SNAPSHOT is mounted on /"
if [ "$CURRENTLY_MOUNTED_SNAPSHOT" == "$SNAPSHOT_TO_RESET" ]; then
    echo "ERROR: You cannot replace a snapshot that is currently in use!" >&2
    exit 1
fi

if [  ! -d "$SNAPSHOTS_DIRECTORY/$SNAPSHOT_SOURCE" ]; then
    echo "ERROR: $SNAPSHOT_SOURCE does not exist! Aborting!" >&2
    exit 1
fi

echo "INFO: Will replace $SNAPSHOT_TO_RESET with a copy of $SNAPSHOT_SOURCE"

if [ -d "$SNAPSHOTS_DIRECTORY/$SNAPSHOT_TO_RESET" ]; then
    btrfs subvolume delete "$SNAPSHOTS_DIRECTORY/$SNAPSHOT_TO_RESET"
else
    echo "WARNING: $SNAPSHOT_TO_RESET does not exist" >&2
fi


echo "INFO: Creating new snapshot $SNAPSHOT_TO_RESET"
btrfs subvolume snapshot "$SNAPSHOTS_DIRECTORY/$SNAPSHOT_SOURCE" "$SNAPSHOTS_DIRECTORY/$SNAPSHOT_TO_RESET"

if [ -d "/.efi/installs/$SNAPSHOT_SOURCE" ]; then
    echo "INFO: Copying kernel..."
    if [ -d "/.efi/installs/$SNAPSHOT_TO_RESET" ]; then
        rm -rf "/.efi/installs/$SNAPSHOT_TO_RESET"
    fi    
    cp -r "/.efi/installs/$SNAPSHOT_SOURCE" "/.efi/installs/$SNAPSHOT_TO_RESET"
else
    echo "WARNING: $SNAPSHOT_SOURCE has no specific kernel copy" >&2
fi