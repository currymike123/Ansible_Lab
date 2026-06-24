#!/bin/bash

# This script is a simple wrapper for running our Ansible playbook.
# It saves us from having to remember and type the full command every time.
# To run: ./nuc setup

# Check if the first argument passed to the script is "setup"
if [ "$1" == "setup" ]; then
    echo "Running the NUC setup playbook..."
    ansible-playbook -i inventory.ini setup_lab.yml --ask-vault-pass
else
    echo "Usage: ./nuc setup"
    exit 1
fi