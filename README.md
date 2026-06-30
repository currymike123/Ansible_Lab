# Ansible_Lab

This repository contains Ansible playbooks for setting up lab accounts for the 24 NUCs in the lab. The playbooks are designed to be run from a control machine that has Ansible installed and is able to connect to the NUCs over SSH.

Currently, only a few of the NUCs are configured in the inventory file. The other NUCs are ignored for now, but can be added to the inventory file as needed once the playbook is tested and working correctly.

- The inventory file lists the NUCs in the lab and their corresponding IP addresses. 
    - '[configured_nucs]' is the group of NUCs that have already been configured and are ready for use. The 'test' account is removed.
    - '[new_nucs]' is the group of NUCs that have not yet been configured. The 'test' account is still present on these NUCs.
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

---

# Ansible YML Quick Reference

## Core Playbook Structure
* **name:** The descriptive title of the playbook or the specific task.
* **hosts:** The group of hosts or individual host to run the playbook against. Refer to your inventory file for the exact host groups (e.g., `new_nucs`).
* **become:** Set to `true` to run the playbook or task with elevated privileges (e.g., using `sudo`).

## Variable Management
Ansible allows you to define variables directly in the playbook or load them from external files, which is highly recommended for sensitive data.

* **vars_files:** A list of external YAML files containing variables. This is the standard method for loading encrypted files, like a `secrets.yml` file containing password hashes.
* **vars:** A block to define key-value pairs directly within the playbook.
    * *Example:* `admin_username: "csadmin"`
* **Variable Interpolation:** Use double curly braces `{{ variable_name }}` to inject a variable's value into your tasks.

## Tasks & Modules
Tasks are executed sequentially on the specified hosts. Each task requires a `name` and calls a specific Ansible module (using the `ansible.builtin.<module_name>` syntax).

### 1. User Management (`ansible.builtin.user`)
Used to create, modify, or delete user accounts.

* **name:** The username.
* **password:** The encrypted password hash.
* **update_password:** Set to `on_create` to only set the password for new accounts, or `always` to force an update.
* **groups:** Comma-separated list of groups the user should belong to (e.g., `sudo`, `users,video,audio`).
* **append:** Set to `true` to add the user to the specified groups without removing them from their current groups. Highly recommended for interactive login accounts.
* **shell:** The default shell for the user (e.g., `/bin/bash`).
* **state:** `present` to create/ensure the user exists, `absent` to remove them.
* **remove:** Set to `true` when `state: absent` to delete the user's home directory.
* **force:** Set to `true` to force the removal of the user, even if they are currently logged in.

### 2. File Operations (`ansible.builtin.copy`)
Used to copy files or inject content directly onto the target hosts.

* **dest:** The absolute path where the file should be created or copied to on the target machine.
* **content:** The raw text to put into the file. Useful for creating small configuration files directly in the playbook (like sudoers files).
* **validate:** A command to run to check the file before saving it.
    * *Example:* `/usr/sbin/visudo -cf %s` ensures you do not lock yourself out with a broken sudoers file.
* **mode:** The file permissions, passed as a string (e.g., `'0440'`).

### 3. Connection Handling (`ansible.builtin.meta`)
Executes Ansible actions rather than target machine actions.

* **reset_connection:** Drops the current SSH connection and establishes a new one. This is critical after adding a user to a new group (like `sudo`) or changing SSH configurations, so the subsequent tasks recognize the new permissions.

### 4. System Operations (`ansible.builtin.reboot`)
Reboots a machine, waits for it to go down, comes back up, and responds to commands.

* **msg:** A custom message to display to logged-in users before the reboot initiates.

## Example: Context and Privilege Shifting
You can change connection details mid-playbook by defining task-level variables. If you delete the user you originally connected with, you must tell Ansible to reconnect as a different, existing user with the correct privileges for the remaining tasks.

````yaml
    - name: Remove the old Test account and delete its home directory
      ansible.builtin.user:
        name: "{{ deprecated_username }}"
        state: absent # state controls whether the user is created or deleted
        remove: true # remove the user's home directory
        force: true # force the removal of the user, even if they are logged in
      
      # We need elevated privileges to delete a user
      become: true
      
      # We tell Ansible to execute THIS specific task 
      # using the new admin user we just created and verified, 
      # instead of the original connection user.
      vars:
        ansible_user: "{{ admin_username }}"
````

---

# Secrets Management

## Secrets File
Sensitive information, such as password hashes, should be stored in a separate `secrets.yml` file. This file should be encrypted using Ansible Vault to prevent unauthorized access.

### Managing the Vault File

**1. Create a new encrypted file:**
```bash
ansible-vault create secrets.yml
```
*(You will be prompted to create and confirm a vault password.)*

**2. Edit an existing encrypted file:**
```bash
ansible-vault edit secrets.yml
```

### File Structure (`secrets.yml`)
Inside the encrypted file, define your variables using standard YAML syntax. For user passwords, Ansible requires the hashed version, not the plaintext password.

```yaml
# Example secrets.yml content
vault_admin_hash: "$6$rounds=...[your_generated_hash_here]..."
vault_student_hash: "$6$rounds=...[your_generated_hash_here]..."
```

*Tip: You can generate a SHA-512 password hash using Python directly in your terminal. Replace 'Enter_Password_Here' with your actual password:*
```bash
python3 -c "import crypt; print(crypt.crypt('Enter_Password_Here', crypt.mksalt(crypt.METHOD_SHA512)))"
```
*Note:* Because the plaintext password is used in the command string, it may be saved in your shell history. You can usually prevent this by typing a space before the `python3` command, or simply clear your history afterward.
*Note:* When you use python to generate the password hash, it will already contain the prefix `$6$rounds=...` which is required for SHA-512 hashes. You do not need to add this prefix manually.

### Running Playbooks with Secrets
When executing a playbook that loads an encrypted `secrets.yml` file, you must provide Ansible with the vault password so it can decrypt the variables at runtime.

**Option A: Prompt for password (Interactive)**
This is the most secure method for manual runs.
```bash
ansible-playbook -i inventory setup_lab.yml --ask-vault-pass
```

**Option B: Use a password file (Automated)**
Create a plain text file (e.g., `.vault_pass`) containing only your vault password. This is useful for automated scripts or CI/CD pipelines.
```bash
ansible-playbook -i inventory setup_lab.yml --vault-password-file .vault_pass
```

