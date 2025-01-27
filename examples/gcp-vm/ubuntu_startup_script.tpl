#!/bin/bash

# Enable connection to the VM's Serial Console
systemctl start serial-getty@ttyS1.service
systemctl enable serial-getty@ttyS1.service
# Installation of pre-requisite packages
apt update && sudo apt upgrade -y
apt install -y curl wget nfs-common qemu-kvm libvirt-clients libvirt-daemon-system cpu-checker virtinst novnc websockify
# Harvester's ISO download
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-amd64.iso -O /var/lib/libvirt/images/harvester.iso && touch /tmp/harvester_download_done
