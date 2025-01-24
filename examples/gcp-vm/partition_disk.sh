#!/bin/bash

DATA_DISK_COUNT=$1
DISK_BASE="/dev/sd"
MOUNT_BASE="/mnt/datadisk"

partition_and_mount() {
  local DISK=$1
  local MOUNT_POINT=$2

  echo "Partitioning and mounting disk $DISK on $MOUNT_POINT..."
  sudo parted --script "$DISK" mklabel gpt
  sudo parted --script "$DISK" mkpart primary ext4 0% 100%
  sudo mkfs.ext4 "${DISK}1"
  sudo mkdir -p "$MOUNT_POINT"
  sudo mount "${DISK}1" "$MOUNT_POINT"
  echo "${DISK}1 $MOUNT_POINT ext4 defaults 0 0" | sudo tee -a /etc/fstab
}

for i in $(seq 1 "$DATA_DISK_COUNT"); do
  DISK="${DISK_BASE}$(echo $((97 + $i)) | awk '{printf("%c", $1)}')"
  MOUNT_POINT="${MOUNT_BASE}${i}"

  if [ -b "$DISK" ]; then
    partition_and_mount "$DISK" "$MOUNT_POINT"
  else
    echo "Error: disk $DISK does not exist."
    exit 1
  fi
done

echo "Configuration completed successfully for $DATA_DISK_COUNT disks."
