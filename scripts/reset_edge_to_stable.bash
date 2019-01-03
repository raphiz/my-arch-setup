#!/usr/bin/env bash
set -eu

# USAGE: ./reset_edge_to_stable.bash
# This script replaces the current EDGE snapshot with a new snapshot of STABLE

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

"$SCRIPT_PATH/_reset.bash" "EDGE" "STABLE"
