#!/bin/bash

# Installation of pre-requisite packages
sudo zypper --non-interactive install parted util-linux virt-install libvirt qemu-kvm python3-websockify novnc socat
systemctl enable --now libvirtd
mkdir -p /srv/tftpboot/
# Download the files needed to start the nested VM
wget https://github.com/harvester/harvester/releases/download/v1.4.0/harvester-v1.4.0-vmlinuz-amd64 -O /srv/tftpboot/harvester-v1.4.0-vmlinuz-amd64
wget https://github.com/harvester/harvester/releases/download/v1.4.0/harvester-v1.4.0-initrd-amd64 -O /srv/tftpboot/harvester-v1.4.0-initrd-amd64
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-rootfs-amd64.squashfs -O /srv/tftpboot/harvester-v1.4.0-rootfs-amd64.squashfs
wget https://raw.githubusercontent.com/glovecchi0/harvester-gcp-tf/refs/heads/feature/ftp-automating-startup/modules/harvester/ipxe.tpl -O /srv/tftpboot/default.ipxe
wget https://raw.githubusercontent.com/glovecchi0/harvester-gcp-tf/refs/heads/feature/ftp-automating-startup/modules/harvester/qemu_custom_network.xml.tpl -O /srv/tftpboot/vlan1.xml
wget https://raw.githubusercontent.com/glovecchi0/harvester-gcp-tf/refs/heads/feature/ftp-automating-startup/modules/harvester/create_cloud_config.yaml.tpl -O /srv/tftpboot/cloud-config.yaml
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-amd64.iso -O /srv/tftpboot/harvester-v1.4.0-amd64.iso && touch /tmp/harvester_download_done
