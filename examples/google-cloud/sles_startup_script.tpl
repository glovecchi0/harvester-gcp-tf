#!/bin/bash

# Installation of pre-requisite packages
sudo zypper --non-interactive install parted util-linux virt-install libvirt qemu-kvm python3-websockify novnc socat
systemctl enable --now libvirtd
# Harvester's ISO download
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-amd64.iso -O /var/lib/libvirt/images/harvester.iso && touch /tmp/harvester_download_done
