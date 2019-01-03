#!/usr/bin/env bash
set -eu

echo "Installing Host $HOSTNAME"

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root, use sudo $0 instead"
   exit 1
fi

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd "$SCRIPT_PATH"

ansible-playbook --ask-vault-pass -l "$HOSTNAME" sites.yml