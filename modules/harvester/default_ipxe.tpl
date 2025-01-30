#!ipxe
set base tftp://192.168.122.1
dhcp
kernel ${base}/harvester-${version}-vmlinuz-amd64 \
    initrd=harvester-${version}-initrd-amd64 \
    ip=dhcp \
    net.ifnames=1 \
    rd.cos.disable \
    rd.noverifyssl \
    root=live:${base}/harvester-${version}-rootfs-amd64.squashfs \
    harvester.install.config_url=${base}/cloud_config.yaml \
    harvester.install.management_interface.interfaces=ens3 \
    harvester.install.automatic=true
initrd ${base}/harvester-${version}-initrd-amd64
boot
