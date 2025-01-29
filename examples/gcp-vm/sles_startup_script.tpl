#!/bin/bash

# Installation of pre-requisite packages
sudo zypper --non-interactive install parted util-linux virt-install libvirt qemu-kvm python3-websockify novnc socat
systemctl enable --now libvirtd
mkdir -p /srv/tftpboot/
# Harvester's Kernel files required
wget https://github.com/harvester/harvester/releases/download/v1.4.0/harvester-v1.4.0-vmlinuz-amd64 -O /srv/tftpboot/harvester-v1.4.0-vmlinuz-amd64
wget https://github.com/harvester/harvester/releases/download/v1.4.0/harvester-v1.4.0-initrd-amd64 -O /srv/tftpboot/harvester-v1.4.0-initrd-amd64
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-rootfs-amd64.squashfs -O /srv/tftpboot/harvester-v1.4.0-rootfs-amd64.squashfs
wget https://raw.githubusercontent.com/glovecchi0/harvester-gcp-tf/refs/heads/feature/ftp-automating-startup/ipxe/ipxe-1.4.0 -O /srv/tftpboot/default.ipxe

# Harvester cloud init file
cat << EOF > /srv/tftpboot/cloudinit.yaml
#cloud-config
scheme_version: 1
token: Myharvester.1234
os:
  password: Myharvester.1234
  hostname: "node1"
install:
  mode: create
  device: /dev/sda
  iso_url: tftp://192.168.122.1/harvester.iso
  tty: ttyS1,115200n8
  vip: 192.168.122.120
  vip_mode: static
EOF

# Harvester custom-network
cat << EOF > /srv/tftpboot/custom-network.xml
<network>
  <name>custom-network</name>
  <uuid>e540559a-f5ea-420b-9d2e-46beaac13cac</uuid>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:ef:58:27'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <tftp root='/srv/tftpboot'/>
    <dhcp>
      <range start='192.168.122.100' end='192.168.122.200'/>
      <bootp file='tftp://192.168.122.1/default.ipxe'/>
    </dhcp>
  </ip>
</network>
EOF
# Harvester's ISO download
wget https://releases.rancher.com/harvester/v1.4.0/harvester-v1.4.0-amd64.iso -O /srv/tftpboot/harvester.iso && touch /tmp/harvester_download_done
