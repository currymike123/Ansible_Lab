# Ansible_Lab

This repository contains Ansible playbooks for setting up lab accounts for the 24 NUCs in the lab. The playbooks are designed to be run from a control machine that has Ansible installed and is able to connect to the NUCs over SSH.

Currently, only the `nuc01` NUC is configured in the inventory file. The other NUCs are ignored for now, but can be added to the inventory file as needed once the playbook is tested and working correctly.

- The inventory file lists the NUCs in the lab and their corresponding IP addresses. 
- The setup_lab.yml playbook creates a new user account on each NUC.

To Run the Playbook in setup mode, run the following command from the control machine:
```bash
# First, make the script executable (you only need to do this once).
chmod +x nuc.sh

# Setup is for the first time you are configuring the NUCs. 
# The NUC should only have the test account on them at this point. 
# The setup will create the lab accounts and configure the NUCs for use.
# Run the setup from within the project directory:
./nuc.sh setup

# To reset accounts on an already configured NUC:
./nuc.sh reset
```

Additonal Playbooks will be created as needed. 