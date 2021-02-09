#!/usr/bin/env bash
set -eu


NEW_SNAPSHOT_NAME=pacman-$(date +"%Y-%m-%d")
if [[ -e "/.snapshots/$NEW_SNAPSHOT_NAME" ]] ; then
    i=1
    while [[ -e "/.snapshots/$NEW_SNAPSHOT_NAME""_$i" ]] ; do
        (( i++ )) || true
    done
    NEW_SNAPSHOT_NAME="$NEW_SNAPSHOT_NAME""_$i"
fi
CURRENTLY_MOUNTED_SNAPSHOT=$(findmnt -n --target=/ -o OPTIONS | sed -E 's/.*subvol=\/@snapshots\/([^,]+*).*/\1/')

# Don't do anything if not on EDGE
if [ "$CURRENTLY_MOUNTED_SNAPSHOT" != "EDGE" ]; then
    exit 0;
fi

# Backup edge
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
"$SCRIPT_PATH/create_new_snapshot.bash" "$NEW_SNAPSHOT_NAME" "EDGE"

# Remove pacman db lock
rm "/.snapshots/$NEW_SNAPSHOT_NAME/var/lib/pacman/db.lck"
