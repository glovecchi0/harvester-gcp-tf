# How to create resources

- Copy `./terraform.tfvars.exmaple` to `./terraform.tfvars`
- Edit `./terraform.tfvars`
  - Update the required variables:
    - `prefix` to give the resources an identifiable name (e.g., your initials or first name)
    - `project_id` to specify in which Project the resources will be created
    - `region` to specify the Google region where resources will be created
    - `instance_count` to specify the number of Server instances to create (to maintain ETCD quorum, the value must be 1, 3, or 5)
- Make sure you are logged into your Google Account from your local Terminal. See the preparatory steps [here](../../modules/google-cloud/README.md).

#### Terraform Apply

```bash
terraform init -upgrade && terraform apply -auto-approve
```

#### Terraform Destroy

```bash
terraform destroy -auto-approve
```

#### OpenTofu Apply

```bash
tofu init -upgrade && tofu apply -auto-approve
```

#### OpenTofu Destroy

```bash
tofu destroy -auto-approve
```

## How to access Google VMs

#### Run the following command (if user is `sles`)

```bash
ssh -oStrictHostKeyChecking=no -i <PREFIX>-ssh_private_key.pem sles@<PUBLIC_IPV4>
```

## How to create the nested Harvester VM

#### Start and enable the virtual network called `default` managed by libvirt

```bash
virsh net-start default
virsh net-autostart default
```

#### Create the nested Harvester VM

```bash
virt-install \
  --name harvester-node \
  --memory 32768 \
  --vcpus 8 \
  --cpu host-passthrough \
  --disk path=/mnt/newdisk/harvester-data.qcow2,size=250,bus=virtio,format=qcow2 \
  --cdrom /var/lib/libvirt/images/harvester.iso \
  --os-type linux \
  --os-variant generic \
  --network bridge=virbr0,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=yourpass \
  --console pty,target_type=serial \
  --boot menu=on,useserial=on,cdrom,hd \
  --autostart
```

## How to proceed with the Harvester ISO installation

#### Expose the nested VM console over WebSocket via noVNC

```bash
websockify --web /usr/share/novnc/ --wrap-mode=ignore 6080 localhost:5900
```

#### Connect to the nested VM console via browser and complete the Harvester ISO installation --> Chrome > `http://<PUBLIC_IPV4>:6080`

## How to connect to the nested VM via SSH

#### Once the ISO installation is complete, the nested VM will reboot and expose the assigned IP

#### Run the following command

```bash
ssh rancher@<NESTED_VM_IPV4> # The password will be the one entered in the previous point
```

## How to connect to the nested VM via browser

#### Run the following command

```bash
socat TCP-LISTEN:443,fork TCP:<NESTED_VM_IPV4>:443
```

#### Connect to the Harvester console via browser --> Chrome > `https://<PUBLIC_IPV4>`

# DEMOSTRATION

#### Google VM deployment

![](../../images/1-tfvars.png)

![](../../images/2-tfapply-1.png)

![](../../images/3-tfapply-2.png)

![](../../images/4-GCP-VM-login.png)

#### Nested VM deployment

![](../../images/5-NestedVM-deploy.png)

![](../../images/6-NestedVM-console-1.png)

#### Harvester ISO installation

![](../../images/7-NestedVM-console-2.png)

![](../../images/8-HW-checks)

![](../../images/9-Installation-mode.png)

![](../../images/10-Data-disk.png)

![](../../images/11-Network-config-1.png)

![](../../images/12-Network-config-2.png)

![](../../images/13-Network-config-3.png)

![](../../images/14-Hostname.png)

![](../../images/15-DNS-Server.png)

![](../../images/16-VIP-config-1.png)

![](../../images/17-VIP-config-2.png)

![](../../images/18-VIP-config-3.png)

![](../../images/19-Token.png)

![](../../images/20-PWD.png)

![](../../images/21-NTP-Server.png)

![](../../images/22-Proxy.png)

![](../../images/23-SSH-key.png)

![](../../images/24-Remote-config.png)

![](../../images/25-Recap.png)

![](../../images/26-Deployment-in-progress.png)

![](../../images/27-Deployment-finished.png)

#### Nested VM access

![](../../images/28-NestedVM-SSH-access.png)

![](../../images/29-NestedVM-browser-access-1.png)

#### Harvester UI access

![](../../images/30-Harvester-UI-1.png)

![](../../images/31-Harvester-UI-2.png)

![](../../images/32-Harvester-UI-3.png)
