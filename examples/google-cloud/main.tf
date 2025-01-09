locals {
  create_ssh_key_pair        = var.create_ssh_key_pair == true ? false : true
  local_ssh_private_key_path = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  local_ssh_public_key_path  = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
  create_vpc                 = var.create_vpc == true ? false : var.create_vpc
  vpc                        = var.vpc == null ? module.harvester_first_node.vpc[0].name : var.vpc
  subnet                     = var.subnet == null ? module.harvester_first_node.subnet[0].name : var.subnet
  create_firewall            = var.create_firewall == true ? false : var.create_firewall
}

module "harvester_first_node" {
  source                = "../../modules/google-cloud/compute-engine"
  prefix                = var.prefix
  project_id            = var.project_id
  region                = var.region
  create_ssh_key_pair   = var.create_ssh_key_pair
  ssh_private_key_path  = local.local_ssh_private_key_path
  ssh_public_key_path   = local.local_ssh_public_key_path
  create_vpc            = var.create_vpc
  vpc                   = var.vpc
  subnet                = var.subnet
  create_firewall       = var.create_firewall
  instance_count        = 1
  instance_type         = var.instance_type
  os_type               = var.os_type
  startup_script        = var.startup_script
  nested_virtualization = var.nested_virtualization
}

/*
module "harvester_additional_nodes" {
  source                = "../../modules/google-cloud/compute-engine"
  prefix                = var.prefix
  project_id            = var.project_id
  region                = var.region
  create_ssh_key_pair   = local.create_ssh_key_pair
  ssh_private_key_path  = local.local_ssh_private_key_path
  ssh_public_key_path   = module.harvester_first_node.public_ssh_key
  create_vpc            = local.create_vpc
  vpc                   = local.vpc
  subnet                = local.subnet
  create_firewall       = local.create_firewall
  instance_count        = var.instance_count - 1
  instance_type         = var.instance_type
  os_type               = var.os_type
  startup_script        = var.startup_script
  nested_virtualization = var.nested_virtualization
}
*/
