# Keep the last 5 automatic pacman snapshots
# Manual snapshots are always ignored

snapshots=($(ls -r -1 /.snapshots/ | grep -E '^pacman-[0-9]{4}-[0-9]{2}-[0-9]{2}(_[0-9]+)?$'))

# Remove the last 5 snapshots
snapshots=("${snapshots[@]:5}")

for SNAPSHOT_NAME in "${snapshots[@]}"
do
   SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
   "$SCRIPT_PATH/delete_snapshot.bash" --force "$SNAPSHOT_NAME"
done
