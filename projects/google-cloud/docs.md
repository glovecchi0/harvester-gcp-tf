## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | 6.19.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 3.0.0-pre1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.35.1 |
| <a name="requirement_ssh"></a> [ssh](#requirement\_ssh) | 2.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_harvester_node"></a> [harvester\_node](#module\_harvester\_node) | ../../modules/google-cloud/compute-engine | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.create_cloud_config_yaml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.default_ipxe_script_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.harvester_startup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.join_cloud_config_yaml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sles_startup_script_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.copy_files_to_first_node](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.harvester_iso_download_checking](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.harvester_node_startup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_harvester_services_startup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [local_file.sles_startup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [local_file.ssh_private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_firewall"></a> [create\_firewall](#input\_create\_firewall) | Specifies whether a Google Firewall should be created for all resources. Default is 'true'. | `bool` | `true` | no |
| <a name="input_create_ssh_key_pair"></a> [create\_ssh\_key\_pair](#input\_create\_ssh\_key\_pair) | Specifies whether a new SSH key pair needs to be created for the instances. Default is 'true'. | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Specifies whether a VPC and Subnet should be created for the instances. Default is 'true'. | `bool` | `true` | no |
| <a name="input_data_disk_size"></a> [data\_disk\_size](#input\_data\_disk\_size) | Specifies the size of the additional data disk for each VM instance, in GB. Default is '350'. | `number` | `350` | no |
| <a name="input_data_disk_type"></a> [data\_disk\_type](#input\_data\_disk\_type) | Specifies the type of the disk attached to each node (e.g., 'pd-standard', 'pd-ssd', or 'pd-balanced'). Default is 'pd-balanced'. | `string` | `"pd-balanced"` | no |
| <a name="input_harvester_cluster_size"></a> [harvester\_cluster\_size](#input\_harvester\_cluster\_size) | Specifies the size of the Harvester cluster. Allowed values are 'small' (8 CPUs, 32 GB RAM) and 'medium' (16 CPUs, 64 GB RAM). Default is 'small'. | `string` | `"small"` | no |
| <a name="input_harvester_first_node_token"></a> [harvester\_first\_node\_token](#input\_harvester\_first\_node\_token) | Specifies the token used to join additional nodes to the Harvester cluster (HA setup). Default is 'SecretToken.123'. | `string` | `"SecretToken.123"` | no |
| <a name="input_harvester_node_count"></a> [harvester\_node\_count](#input\_harvester\_node\_count) | Specifies the number of Harvester nodes to create (1 or 3). Default is '1'. | `number` | `1` | no |
| <a name="input_harvester_password"></a> [harvester\_password](#input\_harvester\_password) | Specifies the password used to access the Harvester nodes. Default is 'SecretPassword.123'. | `string` | `"SecretPassword.123"` | no |
| <a name="input_harvester_version"></a> [harvester\_version](#input\_harvester\_version) | Specifies the Harvester version. Default is 'v1.4.1'. | `string` | `"v1.4.1"` | no |
| <a name="input_ip_cidr_range"></a> [ip\_cidr\_range](#input\_ip\_cidr\_range) | Specifies the range of private IPs available for the Google Subnet. Default is '10.10.0.0/24'. | `string` | `"10.10.0.0/24"` | no |
| <a name="input_os_disk_size"></a> [os\_disk\_size](#input\_os\_disk\_size) | Specifies the size of the disk attached to each node, in GB. Default is '50'. | `number` | `50` | no |
| <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type) | Specifies the type of the disk attached to each node (e.g., 'pd-standard', 'pd-ssd', or 'pd-balanced'). Default is 'pd-balanced'. | `string` | `"pd-balanced"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Specifies the prefix added to the names of all resources. Default is 'gcp-tf'. | `string` | `"gcp-tf"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Specifies the Google Project ID that will contain all created resources. Default is 'gcp-tf'. | `string` | `"gcp-tf"` | no |
| <a name="input_region"></a> [region](#input\_region) | Specifies the Google region used for all resources. Default is 'us-west2'. | `string` | `"us-west2"` | no |
| <a name="input_spot_instance"></a> [spot\_instance](#input\_spot\_instance) | Specifies whether the instances should be Spot (preemptible) VMs. Default is 'true'. | `bool` | `true` | no |
| <a name="input_ssh_private_key_path"></a> [ssh\_private\_key\_path](#input\_ssh\_private\_key\_path) | Specifies the full path where the pre-generated SSH PRIVATE key is located (not generated by Terraform). Default is 'null'. | `string` | `null` | no |
| <a name="input_ssh_public_key_path"></a> [ssh\_public\_key\_path](#input\_ssh\_public\_key\_path) | Specifies the full path where the pre-generated SSH PUBLIC key is located (not generated by Terraform). Default is 'null'. | `string` | `null` | no |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | Specifies a custom startup script to run when the VMs start. Default is 'null'. | `string` | `null` | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | Specifies the Google Subnet used for all resources. Default is 'null'. | `string` | `null` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Specifies the Google VPC used for all resources. Default is 'null'. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_first_instance_private_ip"></a> [first\_instance\_private\_ip](#output\_first\_instance\_private\_ip) | n/a |
| <a name="output_first_instance_public_ip"></a> [first\_instance\_public\_ip](#output\_first\_instance\_public\_ip) | n/a |
| <a name="output_harvester_url"></a> [harvester\_url](#output\_harvester\_url) | n/a |
