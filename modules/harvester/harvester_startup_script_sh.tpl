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
    sleep 30s
  elif [ $i == 2 ]; then
    sudo sed -i "s/${hostname}/${hostname}-$i/g" /srv/www/harvester/join_cloud_config.yaml
    sudo sed -i "s/create_cloud_config.yaml/join_cloud_config.yaml/g" /srv/www/harvester/default.ipxe
    sudo virt-install --name harvester-node-$i --memory 32768 --vcpus 8 --cpu host-passthrough --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 --os-type linux --os-variant generic --network bridge=virbr1,model=virtio --graphics vnc,listen=0.0.0.0,password=yourpass,port=$((5900 + i)) --console pty,target_type=serial --pxe --autostart &
    sleep 30s
  else
    sudo cp /srv/www/harvester/join_cloud_config.yaml /srv/www/harvester/join_cloud_config_$((i - 1)).yaml
    sudo sed -i "s/${hostname}-$((i - 1))/${hostname}-$i/g" /srv/www/harvester/join_cloud_config_$((i - 1)).yaml
    sudo sed -i "s/join_cloud_config.yaml/join_cloud_config_$((i - 1)).yaml/g" /srv/www/harvester/default.ipxe
    sudo virt-install --name harvester-node-$i --memory 32768 --vcpus 8 --cpu host-passthrough --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 --os-type linux --os-variant generic --network bridge=virbr1,model=virtio --graphics vnc,listen=0.0.0.0,password=yourpass,port=$((5900 + i)) --console pty,target_type=serial --pxe --autostart &
    sleep 30s
  fi
done

# Monitoring VM states and restarting them when all are 'shut off'
ALL_SHUT_OFF=false
TIME_LIMIT=600
START_TIME=$(date +%s)
while [ "$ALL_SHUT_OFF" = false ]; do
  SHUT_OFF_COUNT=0
  for i in $(seq 1 ${count}); do
    echo "Checking state of harvester-node-$i: $(sudo virsh domstate harvester-node-$i 2>/dev/null)"
    if [ "$(sudo virsh domstate harvester-node-$i 2>/dev/null)" = "shut off" ]; then
      SHUT_OFF_COUNT=$((SHUT_OFF_COUNT + 1))
    fi
  done
  if [ "$SHUT_OFF_COUNT" -eq "${count}" ]; then
    echo "All $count VMs are 'shut off'. Restarting them..."
    for i in $(seq 1 ${count}); do
      sudo virsh start harvester-node-$i
      echo "harvester-node-$i started."
    done
    ALL_SHUT_OFF=true
  else
    echo "Waiting: Some VMs are still running. Retrying in 30 seconds..."
    sleep 30
  fi
  ELAPSED_TIME=$(($(date +%s) - $START_TIME))
  if [ "$ELAPSED_TIME" -ge "$TIME_LIMIT" ]; then
    echo "Timeout reached. Exiting the script after 10 minutes."
    break
  fi
done

# Expose the Harvester nested VM via the VM's public IP
sudo socat TCP-LISTEN:443,fork TCP:192.168.122.120:443 &
