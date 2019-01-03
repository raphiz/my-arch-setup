#!/usr/bin/env bash
set -eu

CURRENTLY_MOUNTED_SNAPSHOT=$(findmnt -n --target=/ -o OPTIONS | sed -E 's/.*subvol=\/@snapshots\/([^,]+*).*/\1/')

# Don't do anything if not on EDGE
if [ "$CURRENTLY_MOUNTED_SNAPSHOT" != "EDGE" ]; then
    exit 0;
fi

# Backup edge as stable
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
"$SCRIPT_PATH/backup_edge_as_stable.bash"

# Remove pacman db lock
rm /.snapshots/STABLE/var/lib/pacman/db.lck
