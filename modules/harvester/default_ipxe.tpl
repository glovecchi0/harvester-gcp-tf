#!ipxe
dhcp
kernel ${base}/harvester-${version}-vmlinuz-amd64 \
    initrd=harvester-${version}-initrd-amd64 \
    ip=dhcp \
    console=tty1 \
    net.ifnames=1 \
    rd.cos.disable \
    rd.noverifyssl \
    root=live:${base}/harvester-${version}-rootfs-amd64.squashfs \
    harvester.install.config_url=${base}/create_cloud_config.yaml \
    harvester.install.skipchecks=true \
    harvester.install.automatic=true
initrd ${base}/harvester-${version}-initrd-amd64
boot
