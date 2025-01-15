locals {
  create_ssh_key_pair  = var.create_ssh_key_pair == true ? false : true
  ssh_private_key_path = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
  create_vpc           = var.create_vpc == true ? false : var.create_vpc
  vpc                  = var.vpc == null ? module.harvester_first_node.vpc[0].name : var.vpc
  subnet               = var.subnet == null ? module.harvester_first_node.subnet[0].name : var.subnet
  create_firewall      = var.create_firewall == true ? false : var.create_firewall
  ssh_username         = var.instance_os_type
  startup_script       = var.instance_os_type == "ubuntu" ? file("${path.cwd}/ubuntu_startup_script.tpl") : file("${path.cwd}/sles_startup_script.tpl")
}

module "harvester_first_node" {
  source                = "../../modules/google-cloud/compute-engine"
  prefix                = var.prefix
  project_id            = var.project_id
  region                = var.region
  create_ssh_key_pair   = var.create_ssh_key_pair
  ssh_private_key_path  = local.ssh_private_key_path
  ssh_public_key_path   = local.ssh_public_key_path
  ip_cidr_range         = var.ip_cidr_range
  create_vpc            = var.create_vpc
  vpc                   = var.vpc
  subnet                = var.subnet
  create_firewall       = var.create_firewall
  instance_count        = 1
  os_disk_type          = var.os_disk_type
  os_disk_size          = var.os_disk_size
  instance_type         = var.instance_type
  instance_os_type      = var.instance_os_type
  create_data_disk      = var.create_data_disk
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = local.startup_script
  nested_virtualization = var.nested_virtualization
}

data "local_file" "ssh_private_key" {
  depends_on = [module.harvester_first_node]
  filename   = local.ssh_private_key_path
}

resource "null_resource" "disk_partitioning" {
  depends_on = [data.local_file.ssh_private_key]
  provisioner "remote-exec" {
    inline = [
      "sudo parted --script /dev/sdb mklabel gpt",
      "sudo parted --script /dev/sdb mkpart primary ext4 0% 100%",
      "sudo mkfs.ext4 /dev/sdb1",
      "sudo mkdir /mnt/newdisk",
      "sudo mount /dev/sdb1 /mnt/newdisk",
      "sudo echo '/dev/sdb1 /mnt/newdisk ext4 defaults 0 0' | sudo tee -a /etc/fstab"
    ]
    connection {
      type        = "ssh"
      host        = module.harvester_first_node.instances_public_ip[0]
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
}

/*
module "harvester_additional_nodes" {
  source                = "../../modules/google-cloud/compute-engine"
  prefix                = var.prefix
  project_id            = var.project_id
  region                = var.region
  create_ssh_key_pair   = local.create_ssh_key_pair
  ssh_private_key_path  = local.ssh_private_key_path
  ssh_public_key_path   = module.harvester_first_node.public_ssh_key
  ip_cidr_range         = var.ip_cidr_range
  create_vpc            = local.create_vpc
  vpc                   = local.vpc
  subnet                = local.subnet
  create_firewall       = local.create_firewall
  instance_count        = var.instance_count - 1
  os_disk_type          = var.os_disk_type
  os_disk_size          = var.os_disk_size
  instance_type         = var.instance_type
  instance_os_type      = var.instance_os_type
  create_data_disk      = var.create_data_disk
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = var.startup_script
  nested_virtualization = var.nested_virtualization
}
*/
