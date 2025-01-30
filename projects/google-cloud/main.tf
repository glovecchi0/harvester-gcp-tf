locals {
  sles_startup_script_template_file   = "${path.cwd}/sles_startup_script_sh.tpl"
  sles_startup_script_file            = "${path.cwd}/sles_startup_script.sh"
  ubuntu_startup_script_template_file = "${path.cwd}/ubuntu_startup_script_sh.tpl"
  ubuntu_startup_script_file          = "${path.cwd}/ubuntu_startup_script.sh"
  default_ipxe_script_template_file   = "../../modules/harvester/default_ipxe.tpl"
  default_ipxe_script_file            = "${path.cwd}/default.ipxe"
  create_cloud_config_template_file   = "../../modules/harvester/create_cloud_config_yaml.tpl"
  create_cloud_config_file            = "${path.cwd}/create_cloud_config.yaml"
  join_cloud_config_template_file     = "../../modules/harvester/join_cloud_config_yaml.tpl"
  join_cloud_config_file              = "${path.cwd}/join_cloud_config.yaml"
  create_ssh_key_pair                 = var.create_ssh_key_pair == true ? false : true
  ssh_private_key_path                = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  ssh_public_key_path                 = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
  create_vpc                          = var.create_vpc == true ? false : var.create_vpc
  vpc                                 = var.vpc == null ? module.harvester_first_node.vpc[0].name : var.vpc
  subnet                              = var.subnet == null ? module.harvester_first_node.subnet[0].name : var.subnet
  create_firewall                     = var.create_firewall == true ? false : var.create_firewall
  instance_count                      = var.instance_count - 1
  ssh_username                        = var.instance_os_type
  startup_script                      = var.instance_os_type == "ubuntu" ? file("${path.cwd}/local.ubuntu_startup_script_file") : file("${path.cwd}/local.sles_startup_script_file")
  all_instances_ips                   = concat([module.harvester_first_node.instances_public_ip[0]], module.harvester_additional_nodes.instances_public_ip)
  instances_ip_map                    = zipmap(range(length(local.all_instances_ips)), local.all_instances_ips)
}

resource "local_file" "sles_startup_script_config" {
  content = templatefile("${local.sles_startup_script_template_file}", {
    version = var.harvester_version,
    count   = var.data_disk_count
  })
  file_permission = "0644"
  filename        = local.sles_startup_script_file
}

/*
resource "local_file" "ubuntu_startup_script_config" {
  content = templatefile("${local.ubuntu_startup_script_template_file}", {
    version = var.harvester_version,
    count   = var.data_disk_count
  })
  file_permission = "0644"
  filename        = local.ubuntu_startup_script_file
}
*/

resource "local_file" "default_ipxe_script_config" {
  content = templatefile("${local.default_ipxe_script_template_file}", {
    version = var.harvester_version
  })
  file_permission = "0644"
  filename        = local.default_ipxe_script_file
}

resource "local_file" "create_cloud_config_yaml" {
  content = templatefile("${local.create_cloud_config_template_file}", {
    version  = var.harvester_version
    token    = var.harvester_first_node_token
    password = var.harvester_password
    hostname = "${var.prefix}-1"
  })
  file_permission = "0644"
  filename        = local.create_cloud_config_file
}

/*
resource "local_file" "join_cloud_config_yaml" {
  content = templatefile("${local.join_cloud_config_template_file}", {
    version  = var.harvester_version
    token    = var.harvester_first_node_token
    password = var.harvester_password
    hostname = "${var.prefix}-1"
  })
  file_permission = "0644"
  filename        = local.join_cloud_config_file
}
*/

module "harvester_first_node" {
  depends_on            = [local_file.sles_startup_script_config]
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
  data_disk_count       = var.data_disk_count
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = local.startup_script
  nested_virtualization = var.nested_virtualization
}

module "harvester_additional_nodes" {
  depends_on            = [module.harvester_first_node]
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
  instance_count        = local.instance_count
  os_disk_type          = var.os_disk_type
  os_disk_size          = var.os_disk_size
  instance_type         = var.instance_type
  instance_os_type      = var.instance_os_type
  create_data_disk      = var.create_data_disk
  data_disk_count       = var.data_disk_count
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = local.startup_script
  nested_virtualization = var.nested_virtualization
}

resource "null_resource" "wait_for_ips" {
  depends_on = [
    module.harvester_first_node,
    module.harvester_additional_nodes
  ]
}

data "local_file" "ssh_private_key" {
  depends_on = [module.harvester_additional_nodes, null_resource.wait_for_ips]
  filename   = local.ssh_private_key_path
}

resource "null_resource" "harvester_iso_download_checking" {
  depends_on = [data.local_file.ssh_private_key]
  for_each   = local.instances_ip_map
  provisioner "remote-exec" {
    inline = [
      "while true; do [ -f '/tmp/harvester_download_done' ] && break || echo 'The download of the Harvester ISO is not yet complete. Checking again in 30 seconds...' && sleep 30; done"
    ]
    connection {
      type        = "ssh"
      host        = each.value
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
}

resource "null_resource" "harvester_first_node_startup" {
  depends_on = [null_resource.harvester_iso_download_checking]
  provisioner "remote-exec" {
    inline = [
      "sudo virsh net-define /srv/tftpboot/vlan1.xml",
      "sudo virsh net-start vlan1",
      "sudo virsh net-autostart vlan1"
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
resource "null_resource" "harvester_additional_nodes_startup" {
  depends_on = [null_resource.harvester_iso_download_checking, null_resource.disk_partitioning]
  for_each   = local.instances_ip_map
  provisioner "remote-exec" {
    inline = [
      "sudo virsh net-define /srv/tftpboot/vlan1.xml",
      "sudo virsh net-start vlan1",
      "sudo virsh net-autostart vlan1"
    ]
    connection {
      type        = "ssh"
      host        = each.value
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
}
*/
