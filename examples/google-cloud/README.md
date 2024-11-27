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
