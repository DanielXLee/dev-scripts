#!/usr/bin/env bash

NEW_DISK=${NEW_DISK:-/dev/vdb}
MOUNT_POINT=${MOUNT_POINT:-/extend/vdb}

if [[ "$NEW_DISK" == "/dev/vdb" ]]; then
  read -rp "Enter new disk [/dev/vdb]: " NEW_DISK
  NEW_DISK=${NEW_DISK:-/dev/vdb}
fi
if [[ "$MOUNT_POINT" == "/extend/vdb" ]]; then
  read -rp "Enter mount point [/extend/vdb]: " MOUNT_POINT
  MOUNT_POINT=${MOUNT_POINT:-/extend/vdb}
fi

read -rp "Do you want to mount disk $NEW_DISK to point $MOUNT_POINT (y/n)? " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0

mkfs -t ext4 $NEW_DISK
mkdir -p $MOUNT_POINT
echo "$NEW_DISK           $MOUNT_POINT          ext4     defaults       0 0" >> /etc/fstab
