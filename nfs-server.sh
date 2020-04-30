#!/usr/bin/env bash
# Quick create a nsf server

SERVER_IP=${SERVER_IP:-}

apt-get install nfs-kernel-server -y

# Exports mount directory
echo "/nfsserver/ ${SERVER_IP}/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
systemctl restart nfs-kernel-server


mount -t nfs ${SERVER_IP}:/nfsserver/3.1.0 /var/lib/testregistry -o proto=tcp -o nolock
