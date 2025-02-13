## How to create a Basic Ubuntu Virtual Machine and how to access it via SSH from local CLI


#### Export kubeConfig file a to access Harvester cluster from CLI

```console
export kubeconfig=<prefix>_kube_config.yaml
```
![](../images/VM_SETUP_AND_SSH_LOGIN-1.png)

#### Access Harvester UI to upload Ubuntu Image

```console
URL: https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
```
![](../images/VM_SETUP_AND_SSH_LOGIN-2.png)

#### Create user-data Cloud Configuration Template in Harvester with the following Script

```console
#!/bin/bash
sudo adduser -U -m "ubuntu"
echo "ubuntu:ubuntu" | chpasswd
sudo sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s@Include /etc/ssh/sshd_config.d/\*.conf@#Include /etc/ssh/sshd_config.d/*.conf@g" /etc/ssh/sshd_config
sudo systemctl restart ssh
```
![](../images/VM_SETUP_AND_SSH_LOGIN-3.png)


#### Create Ubuntu Virtual Machine using ubuntu image and User-data template previously defined

![](../images/VM_SETUP_AND_SSH_LOGIN-4.png)

#### Install Virtctl command in your CLI

```console
export VERSION=v0.54.0
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-darwin-amd64
mv virtctl-v0.54.0-darwin-amd64 virtctl
chmod +x virtctl
sudo mv virtctl /usr/local/bin/
virtctl version
```

#### Install Virtctl command in your CLI

```console
export VERSION=v0.54.0
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-darwin-amd64
mv virtctl-v0.54.0-darwin-amd64 virtctl
chmod +x virtctl
sudo mv virtctl /usr/local/bin/
virtctl version
```

#### How to access Ubuntu machine created through virtctl from CLI 

```console
kubectl -n <VM_NAMESPACE> get vmi
virtctl ssh --local-ssh=true <SSH_USERNAME>@vmi/<VM_NAME>.<VM_NAMESPACE>
```

![](../images/VM_SETUP_AND_SSH_LOGIN-5.png)