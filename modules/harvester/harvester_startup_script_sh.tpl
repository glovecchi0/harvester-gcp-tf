for i in $(seq 1 "${count}")
  do if [ $i == "1" ]
       then
         sudo virt-install   --name harvester-node-$i   --memory 32768   --vcpus 8   --cpu host-passthrough   --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2   --os-type linux   --os-variant generic   --network bridge=virbr1,model=virtio   --graphics vnc,listen=0.0.0.0,password=yourpass   --console pty,target_type=serial   --pxe &
         sleep 30s
     elif [ $i == "2" ]
       then
         sed "s/to-replace/${hostname}-$i/g" /srv/www/harvester/join_cloud_config.yaml  > /srv/www/harvester/join_cloud_config-$i.yaml
         sed -i "s/create_cloud_config.yaml/join_cloud_config-$${i}.yaml/g" /srv/www/harvester/default.ipxe
         virt-install   --name harvester-node-$i   --memory 32768   --vcpus 8   --cpu host-passthrough   --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2   --os-type linux   --os-variant generic   --network bridge=virbr1,model=virtio   --graphics vnc,listen=0.0.0.0,password=yourpass,port=5901   --console pty,target_type=serial   --pxe &
         sleep 30s
     elif [ $i == "3" ]
       then
         sed "s/to-replace/${hostname}-$i/g" /srv/www/harvester/join_cloud_config.yaml  > /srv/www/harvester/join_cloud_config-$i.yaml
         sed -i "s/create_cloud_config.yaml/join_cloud_config-$${i}.yaml/g" /srv/www/harvester/default.ipxe
         virt-install   --name harvester-node-$i   --memory 32768   --vcpus 8   --cpu host-passthrough   --disk path=/mnt/datadisk$i/harvester-data.qcow2,size=250,bus=virtio,format=qcow2   --os-type linux   --os-variant generic   --network bridge=virbr1,model=virtio   --graphics vnc,listen=0.0.0.0,password=yourpass,port=5902   --console pty,target_type=serial   --pxe &
     fi
done

#Exposing Harvester to internet
socat TCP-LISTEN:443,fork TCP:192.168.122.120:443 &