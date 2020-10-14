#!/bin/bash

# Setup Python 3 venv, activate it, and add to bashrc
python3 -m venv ${HOME}/${USER}-py3
source ${HOME}/${USER}-py3/bin/activate
echo "source ${HOME}/${USER}-py3/bin/activate" >> ${HOME}/.bashrc

# Install ansible
pip install ansible

# Make sure $HOME/bin exists and is on PATH, fix that if not
if ! [[ -d ${HOME}/bin ]]; then
    mkdir ${HOME}/bin
fi

if ! [[ :$PATH: == *:"${HOME}/bin":* ]]; then
    export PATH=${PATH}:${HOME}/bin
    echo "export PATH=${PATH}:${HOME}/bin" >> ${HOME}/.bashrc
fi

# Grab getinv.sh and install it
wget -O ${HOME}/bin/getinv https://raw.githubusercontent.com/colindclare/provision-ansible-nxlogin/master/getinv.sh
chmod 700 ${HOME}/bin/getinv 

# Create general Ansiblle directory structure
echo "Creating typical Ansible directories and baseline .ansible.cfg in ${HOME}"
mkdir -p ${HOME}/ansible/{vars/group_vars,vars/host_vars,inventories,roles,playbooks,scrips,templates,files}

# Create basic ansible.cfg in home dir
cat > ${HOME}/.ansible.cfg << EOF

[defaults]
private_key_file = ${HOME}/.ssh/nex$(whoami).id_rsa
host_key_checking = False
[inventory]
[privilege_escalation]
[paramiko_connection]
[ssh_connection]
[persistent_connection]
[sudo_become_plugin]
[selinux]
[colors]
[diff]
[galaxy]

EOF

# Generate cluster inventories
echo "Generating NX Cluster inventory files"
${HOME}/bin/getinv

# Final messages
cat << EOF

Inventories generated, one file per cluster, in ${HOME}/ansible/inventories.

Additionally, commonly used Ansible directories are also available in ${HOME}/ansible.

Please refer to Ansible's documentation for help with commonly used modules:
https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html#plugins-in-ansible-builtin
https://docs.ansible.com/ansible/latest/collections/ansible/posix/index.html#plugins-in-ansible-posix

The folllowing guide will help in constructing ad hoc commands, playbooks, and generally understanding the basics of Ansible:
https://www.tutorialspoint.com/ansible/index.htm

EOF
