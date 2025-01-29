locals {
  create_ssh_key_pair  = var.create_ssh_key_pair == true ? false : true
  ssh_private_key_path = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
  create_vpc           = var.create_vpc == true ? false : var.create_vpc
  vpc                  = var.vpc == null ? module.harvester_first_node.vpc[0].name : var.vpc
  subnet               = var.subnet == null ? module.harvester_first_node.subnet[0].name : var.subnet
  create_firewall      = var.create_firewall == true ? false : var.create_firewall
  instance_count       = var.instance_count - 1
  ssh_username         = var.instance_os_type
  startup_script       = var.instance_os_type == "ubuntu" ? file("${path.cwd}/ubuntu_startup_script.tpl") : file("${path.cwd}/sles_startup_script.tpl")
  all_instances_ips    = concat([module.harvester_first_node.instances_public_ip[0]], module.harvester_additional_nodes.instances_public_ip)
  instances_ip_map     = zipmap(range(length(local.all_instances_ips)), local.all_instances_ips)
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
  data_disk_count       = var.data_disk_count
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = local.startup_script
  nested_virtualization = var.nested_virtualization
}

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

resource "null_resource" "disk_partitioning" {
  depends_on = [data.local_file.ssh_private_key]
  for_each   = local.instances_ip_map
  provisioner "file" {
    source      = "${path.cwd}/partition_disk.sh"
    destination = "/tmp/partition_disk.sh"
    connection {
      type        = "ssh"
      host        = each.value
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/partition_disk.sh",
      "sudo bash -c '/tmp/partition_disk.sh ${var.data_disk_count}'"
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
  depends_on = [null_resource.harvester_iso_download_checking, null_resource.disk_partitioning]
  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/VERSION/${var.harvester_version}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/TOKEN/${var.harvester_first_node_token}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/PASSWORD/${var.harvester_password}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/HOSTNAME/${var.prefix}-1/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/VERSION/${var.harvester_version}/g' /srv/tftpboot/default.ipxe",
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
      "sudo sed -i 's/VERSION/${var.harvester_version}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/TOKEN/${var.harvester_first_node_token}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/PASSWORD/${var.harvester_password}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/HOSTNAME/${var.prefix}/g' /srv/tftpboot/cloud-config.yaml",
      "sudo sed -i 's/VERSION/${var.harvester_version}/g' /srv/tftpboot/default.ipxe",
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
