#!/bin/bash

# Starting the Virtual Network
sudo virsh net-define /srv/www/harvester/vlan1.xml
sudo virsh net-start vlan1
sudo virsh net-autostart vlan1

# Creation of nested VMs, based on the number of data disks
for i in $(seq 1 ${count}); do
  if [ $i == 1 ]; then
    sudo sed -i "s/${hostname}/${hostname}-$i/g" /srv/www/harvester/create_cloud_config.yaml
    sudo virt-install --name harvester-node-$i --memory 32768 --vcpus 8 --cpu host-passthrough --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 --os-type linux --os-variant generic --network bridge=virbr1,model=virtio --graphics vnc,listen=0.0.0.0,password=yourpass,port=$((5900 + i)) --console pty,target_type=serial --pxe --autostart &
    sleep 30
  elif [ $i == 2 ]; then
    sudo sed -i "s/${hostname}/${hostname}-$i/g" /srv/www/harvester/join_cloud_config.yaml
    sudo sed -i "s/create_cloud_config.yaml/join_cloud_config.yaml/g" /srv/www/harvester/default.ipxe
    sudo virt-install --name harvester-node-$i --memory 32768 --vcpus 8 --cpu host-passthrough --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 --os-type linux --os-variant generic --network bridge=virbr1,model=virtio --graphics vnc,listen=0.0.0.0,password=yourpass,port=$((5900 + i)) --console pty,target_type=serial --pxe --autostart &
    sleep 30
  else
    sudo cp /srv/www/harvester/join_cloud_config.yaml /srv/www/harvester/join_cloud_config_$((i - 1)).yaml
    sudo sed -i "s/${hostname}-$((i - 1))/${hostname}-$i/g" /srv/www/harvester/join_cloud_config_$((i - 1)).yaml
    sudo sed -i "s/join_cloud_config.yaml/join_cloud_config_$((i - 1)).yaml/g" /srv/www/harvester/default.ipxe
    sudo virt-install --name harvester-node-$i --memory 32768 --vcpus 8 --cpu host-passthrough --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 --os-type linux --os-variant generic --network bridge=virbr1,model=virtio --graphics vnc,listen=0.0.0.0,password=yourpass,port=$((5900 + i)) --console pty,target_type=serial --pxe --autostart &
    sleep 30
  fi
done

# Monitoring VM states and restarting them when all are 'shut off'
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * virsh list --all | awk 'NR>2 && \$3 == \"shut\" {print \$2}' | xargs -r -I{} virsh start {}") | sudo crontab -

# Expose the Harvester nested VM via the VM's public IP
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * [ ! \$(pgrep -x socat) ] && sudo socat TCP-LISTEN:443,fork TCP:192.168.122.120:443 > /dev/null 2>&1 &") | sudo crontab -
