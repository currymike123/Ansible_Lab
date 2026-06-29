#!/bin/bash

# This script is a simple wrapper for running our Ansible playbook.
# It saves us from having to remember and type the full command every time.


# Check if the first argument passed to the script is "setup"
if [[ "$1" == "setup" ]]; then
    echo "Running the NUC setup playbook..."
    ansible-playbook -i inventory.ini setup_lab.yml --ask-vault-pass --ask-pass --ask-become-pass -e ansible_user=test
elif [[ "$1" == "reset" ]]; then
    echo "Running the NUC reset playbook..."
    ansible-playbook -i inventory.ini reset_lab.yml --ask-vault-pass --ask-pass --ask-become-pass -e ansible_user=csadmin
else
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  setup   - Initial NUC setup (requires 'test' user)"
    echo "  reset   - Update/Reset accounts (requires 'csadmin' user)"
    exit 1
fi