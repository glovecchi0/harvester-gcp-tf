#!/bin/bash

# Enable connection to the VM's Serial Console
systemctl start serial-getty@ttyS1.service
systemctl enable serial-getty@ttyS1.service

# Installation of pre-requisite packages
apt update && sudo apt upgrade -y
apt install -y curl wget nfs-common qemu-kvm libvirt-clients libvirt-daemon-system cpu-checker virtinst novnc websockify

# Download the files needed to start the nested VM
wget https://github.com/harvester/harvester/releases/download/${version}/harvester-${version}-vmlinuz-amd64 -O /srv/tftpboot/harvester-${version}-vmlinuz-amd64
wget https://github.com/harvester/harvester/releases/download/${version}/harvester-${version}-initrd-amd64 -O /srv/tftpboot/harvester-${version}-initrd-amd64
wget https://releases.rancher.com/harvester/${version}/harvester-${version}-rootfs-amd64.squashfs -O /srv/tftpboot/harvester-${version}-rootfs-amd64.squashfs
wget https://releases.rancher.com/harvester/${version}/harvester-${version}-amd64.iso -O /srv/tftpboot/harvester-${version}-amd64.iso && touch /tmp/harvester_download_done

# Disk partitioning
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

for i in $(seq 1 "${count}"); do
  DISK="${DISK_BASE}$(echo $((97 + $i)) | awk '{printf("%c", $1)}')"
  MOUNT_POINT="${MOUNT_BASE}${i}"

  if [ -b "$DISK" ]; then
    partition_and_mount "$DISK" "$MOUNT_POINT"
  else
    echo "Error: disk $DISK does not exist."
    exit 1
  fi
done

echo "Configuration completed successfully for ${count} disks."
