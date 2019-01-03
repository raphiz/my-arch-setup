#!/usr/bin/env bash
set -eu

# USAGE: ./backup_edge_as_stable.bash
# This script replaces the current STABLE snapshot with a new snapshot of EDGE

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

"$SCRIPT_PATH/_reset.bash" "STABLE" "EDGE"
