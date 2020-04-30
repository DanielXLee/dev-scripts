#!/bin/bash
# Run a shell script on all the nodes with ansible
# Pre-condition:
# 1. ansible installed on local
# 2. none-password ssh access configed

which ansible || (echo "ansible is not installed." && exit 1)

# config proxy
inventory=$1
ansible all -i $inventory -m script -a 'config_proxy.sh'
