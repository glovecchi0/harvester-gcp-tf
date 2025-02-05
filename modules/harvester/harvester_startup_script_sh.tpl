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
ALL_SHUT_OFF=false
while [ "$ALL_SHUT_OFF" = false ]; do
  SHUT_OFF_COUNT=0
  for i in $(seq 1 "${count}"); do
    STATE=$(sudo virsh domstate "harvester-node-$i" 2>/dev/null | tr -d '[:space:]')
    echo "Checking state of harvester-node-$i: $STATE"
    if [ "$STATE" = "shutoff" ]; then
      sudo virsh start "harvester-node-$i"
      echo "harvester-node-$i started."
      SHUT_OFF_COUNT=$((SHUT_OFF_COUNT + 1))
    fi
  done
  if [ "$SHUT_OFF_COUNT" -eq "${count}" ]; then
    ALL_SHUT_OFF=true
    echo "All VMs have been restarted."
  else
    echo "Some VMs are still running. Retrying in 30 seconds..."
    sleep 30
  fi
done

# Expose the Harvester nested VM via the VM's public IP
sudo nohup socat TCP-LISTEN:443,fork TCP:192.168.122.120:443 > /dev/null 2>&1 &
