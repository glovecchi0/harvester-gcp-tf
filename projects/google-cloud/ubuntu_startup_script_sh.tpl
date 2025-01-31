#!/bin/bash

# Enable connection to the VM's Serial Console
systemctl start serial-getty@ttyS1.service
systemctl enable serial-getty@ttyS1.service

# Installation of pre-requisite packages
apt update && sudo apt upgrade -y
apt install -y curl wget nfs-common qemu-kvm libvirt-clients libvirt-daemon-system cpu-checker virtinst novnc websockify

# Download the files needed to start the nested VM
sudo curl -L -o /srv/tftpboot/harvester-${version}-vmlinuz-amd64 \
  https://github.com/harvester/harvester/releases/download/${version}/harvester-${version}-vmlinuz-amd64
sudo curl -L -o /srv/tftpboot/harvester-${version}-initrd-amd64 \
  https://github.com/harvester/harvester/releases/download/${version}/harvester-${version}-initrd-amd64
sudo curl -L -o /srv/tftpboot/harvester-${version}-rootfs-amd64.squashfs \
  https://releases.rancher.com/harvester/${version}/harvester-${version}-rootfs-amd64.squashfs
sudo curl -L -o /srv/tftpboot/harvester-${version}-amd64.iso \
  https://releases.rancher.com/harvester/${version}/harvester-${version}-amd64.iso && \
  touch /tmp/harvester_download_done

# Disk partitioning
for i in $(seq 1 "${count}"); do
  if [ -b "${disk_name}$(printf "\x$(printf %x $((96 + i)))")" ]; then
    echo "Partitioning and mounting disk ${disk_name}$(printf "\x$(printf %x $((96 + i)))") on ${mount_point}${count}..."
    sudo parted --script "${disk_name}$(printf "\x$(printf %x $((96 + i)))")" mklabel gpt
    sudo parted --script "${disk_name}$(printf "\x$(printf %x $((96 + i)))")" mkpart primary ext4 0% 100%
    sudo mkfs.ext4 "${disk_name}$(printf "\x$(printf %x $((96 + i)))")1"
    sudo mkdir -p "${mount_point}${count}"
    sudo mount "${disk_name}$(printf "\x$(printf %x $((96 + i)))")1" "${mount_point}${count}"
    echo "${disk_name}$(printf "\x$(printf %x $((96 + i)))")1 ${mount_point}${count} ext4 defaults 0 0" | sudo tee -a /etc/fstab
  else
    echo "Error: disk ${disk_name}$(printf "\x$(printf %x $((96 + i)))") does not exist."
    exit 1
  fi
done
echo "Configuration completed successfully for ${count} disks."
