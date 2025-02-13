# How to create resources

- Copy `./terraform.tfvars.exmaple` to `./terraform.tfvars`
- Edit `./terraform.tfvars`
  - Update the required variables:
    - `prefix` to give the resources an identifiable name (e.g., your initials or first name)
    - `project_id` to specify in which Project the resources will be created
    - `region` to specify the Google region where resources will be created
    - `harvester_node_count` to specify the number of Harvester nodes to create (1 or 3)
    - `harvester_cluster_size` To specify the size Harvester nodes created.(small or medium)
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

## How to execute kubectl commands to Harvester cluster

#### Run the following command

```bash
export KUBECONFIG=<prefix>_kube_config.yaml
```

## How to access Google VMs

#### Run the following command

```bash
ssh -oStrictHostKeyChecking=no -i <PREFIX>-ssh_private_key.pem sles@<PUBLIC_IPV4>
```

## How to access Harvester Nested VMs

#### Run the following command within Google VM where harvester is running

```bash
ssh rancher@<NESTED_VM_IPV4> # The password can be obtained from variable harvester_password or from join/create_cloud_config.yaml file in the current folder
```

# DEMOSTRATION (Harvester with 3 small nodes)

#### Terraform execution process and Harvester UI access

```console
$ cat terraform.tfvars
prefix = "jlagos"
project_id = "<project-id>"
region = "europe-west8"
harvester_node_count = 3
harvester_cluster_size = "small"
```

![](../../images/GCP_PROJ_README_1.png)
![](../../images/GCP_PROJ_README_2.png)
![](../../images/GCP_PROJ_README_3.png)
![](../../images/GCP_PROJ_README_4.png)
![](../../images/GCP_PROJ_README_5.png)

#### SSH into GCP VM

![](../../images/GCP_PROJ_README_6.png)

#### SSH from GCP VM to Harvester Nested VM

![](../../images/GCP_PROJ_README_7.png)

#### Kubectl commands execution

![](../../images/GCP_PROJ_README_8.png)
