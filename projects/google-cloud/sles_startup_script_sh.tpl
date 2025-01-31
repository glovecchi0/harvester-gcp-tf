#!/bin/bash

# Installation of pre-requisite packages
sudo zypper --non-interactive install parted util-linux virt-install libvirt qemu-kvm python3-websockify novnc socat
sudo systemctl enable --now libvirtd
sudo mkdir -p /srv/tftpboot/

# Download the files needed to start the nested VM
sudo curl -L -o /srv/tftpboot/vlan1.xml \
  https://raw.githubusercontent.com/glovecchi0/harvester-gcp-tf/refs/heads/feature/ftp-automating-startup/modules/harvester/qemu_vlan1_xml.tpl
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
  if [ -b "${disk_name}$(printf "\x$(printf %x $((97 + i)))")" ]; then
    echo "Partitioning and mounting disk ${disk_name}$(printf "\x$(printf %x $((97 + i)))") on ${mount_point}$i..."
    sudo parted --script "${disk_name}$(printf "\x$(printf %x $((97 + i)))")" mklabel gpt
    sudo parted --script "${disk_name}$(printf "\x$(printf %x $((97 + i)))")" mkpart primary ext4 0% 100%
    sudo mkfs.ext4 "${disk_name}$(printf "\x$(printf %x $((97 + i)))")1"
    sudo mkdir -p "${mount_point}$i"
    sudo mount "${disk_name}$(printf "\x$(printf %x $((97 + i)))")1" "${mount_point}$i"
    echo "${disk_name}$(printf "\x$(printf %x $((97 + i)))")1 ${mount_point}$i ext4 defaults 0 0" | sudo tee -a /etc/fstab
  else
    echo "Error: disk ${disk_name}$(printf "\x$(printf %x $((97 + i)))") does not exist."
    exit 1
  fi
done
echo "Configuration completed successfully for ${count} disks."
