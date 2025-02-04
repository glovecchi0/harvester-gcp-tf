locals {
  sles_startup_script_template_file      = "../../modules/harvester/sles_startup_script_sh.tpl"
  sles_startup_script_file               = "${path.cwd}/sles_startup_script.sh"
  data_disk_name                         = "/dev/sd"
  data_disk_mount_point                  = "/mnt/datadisk"
  default_ipxe_script_template_file      = "../../modules/harvester/default_ipxe.tpl"
  default_ipxe_script_file               = "${path.cwd}/default.ipxe"
  ipxe_base_url                          = "http://192.168.122.1"
  create_cloud_config_template_file      = "../../modules/harvester/create_cloud_config_yaml.tpl"
  create_cloud_config_file               = "${path.cwd}/create_cloud_config.yaml"
  join_cloud_config_template_file        = "../../modules/harvester/join_cloud_config_yaml.tpl"
  join_cloud_config_file                 = "${path.cwd}/join_cloud_config.yaml"
  harvester_startup_script_template_file = "../../modules/harvester/harvester_startup_script_sh.tpl"
  harvester_startup_script_file          = "${path.cwd}/harvester_startup_script.sh"
  create_ssh_key_pair                    = var.create_ssh_key_pair == true ? false : true
  ssh_private_key_path                   = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  ssh_public_key_path                    = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
  create_vpc                             = var.create_vpc == true ? false : var.create_vpc
  vpc                                    = var.vpc == null ? module.harvester_node.vpc[0].name : var.vpc
  subnet                                 = var.subnet == null ? module.harvester_node.subnet[0].name : var.subnet
  create_firewall                        = var.create_firewall == true ? false : var.create_firewall
  ssh_username                           = "sles"
  instance_type = (
    var.data_disk_count == 1 ? "n2-standard-16" :
    var.data_disk_count == 2 ? "n2-standard-32" :
    var.data_disk_count == 3 ? "n2-standard-64" :
    "n2-standard-16"
  )
}

resource "local_file" "sles_startup_script_config" {
  content = templatefile("${local.sles_startup_script_template_file}", {
    version     = var.harvester_version,
    count       = var.data_disk_count,
    disk_name   = local.data_disk_name,
    mount_point = local.data_disk_mount_point
  })
  file_permission = "0644"
  filename        = local.sles_startup_script_file
}

data "local_file" "sles_startup_script" {
  depends_on = [local_file.sles_startup_script_config]
  filename   = local.sles_startup_script_file
}

resource "local_file" "default_ipxe_script_config" {
  content = templatefile("${local.default_ipxe_script_template_file}", {
    version = var.harvester_version
    base    = local.ipxe_base_url
  })
  file_permission = "0644"
  filename        = local.default_ipxe_script_file
}

resource "local_file" "create_cloud_config_yaml" {
  content = templatefile("${local.create_cloud_config_template_file}", {
    version  = var.harvester_version,
    token    = var.harvester_first_node_token,
    hostname = var.prefix,
    password = var.harvester_password
  })
  file_permission = "0644"
  filename        = local.create_cloud_config_file
}


resource "local_file" "join_cloud_config_yaml" {
  content = templatefile("${local.join_cloud_config_template_file}", {
    version  = var.harvester_version,
    token    = var.harvester_first_node_token,
    hostname = var.prefix,
    password = var.harvester_password
  })
  file_permission = "0644"
  filename        = local.join_cloud_config_file
}

resource "local_file" "harvester_startup_script" {
  content = templatefile("${local.harvester_startup_script_template_file}", {
    hostname  = var.prefix
    public_ip = module.harvester_node.instances_public_ip
    count     = var.data_disk_count
  })
  file_permission = "0644"
  filename        = local.harvester_startup_script_file
}


module "harvester_node" {
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
  os_disk_type          = var.os_disk_type
  os_disk_size          = var.os_disk_size
  instance_type         = local.instance_type
  create_data_disk      = var.create_data_disk
  data_disk_count       = var.data_disk_count
  data_disk_type        = var.data_disk_type
  data_disk_size        = var.data_disk_size
  startup_script        = data.local_file.sles_startup_script.content
  nested_virtualization = var.nested_virtualization
}

data "local_file" "ssh_private_key" {
  depends_on = [module.harvester_node]
  filename   = local.ssh_private_key_path
}

resource "null_resource" "harvester_iso_download_checking" {
  depends_on = [data.local_file.ssh_private_key]
  provisioner "remote-exec" {
    inline = [
      "while true; do [ -f '/tmp/harvester_download_done' ] && break || echo 'The download of the Harvester ISO is not yet complete. Checking again in 30 seconds...' && sleep 30; done"
    ]
    connection {
      type        = "ssh"
      host        = module.harvester_node.instances_public_ip[0]
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
}

resource "null_resource" "copy_files_to_first_node" {
  depends_on = [null_resource.harvester_iso_download_checking]
  for_each = {
    "default.ipxe"                    = local.default_ipxe_script_file
    "create_cloud_config_yaml.tpl"    = local.create_cloud_config_file
    "join_cloud_config_yaml.tpl"      = local.join_cloud_config_file
    "harvester_startup_script_sh.tpl" = local.harvester_startup_script_file
  }
  connection {
    type        = "ssh"
    host        = module.harvester_node.instances_public_ip[0]
    user        = local.ssh_username
    private_key = data.local_file.ssh_private_key.content
  }
  provisioner "file" {
    source      = each.value
    destination = "/tmp/${basename(each.value)}"
  }
}

resource "null_resource" "harvester_node_startup" {
  depends_on = [null_resource.copy_files_to_first_node]
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/${basename(local.default_ipxe_script_file)} /tmp/${basename(local.create_cloud_config_file)} /tmp/${basename(local.join_cloud_config_file)} /tmp/${basename(local.harvester_startup_script_file)} /srv/www/harvester/",
      "bash /srv/www/harvester/${basename(local.harvester_startup_script_file)}"
    ]
    connection {
      type        = "ssh"
      host        = module.harvester_node.instances_public_ip[0]
      user        = local.ssh_username
      private_key = data.local_file.ssh_private_key.content
    }
  }
}

resource "null_resource" "wait_harvester_services_startup" {
  depends_on = [null_resource.harvester_node_startup]
  provisioner "local-exec" {
    command     = <<-EOF
      count=0
      while [ "$${count}" -lt 15 ]; do
        resp=$(curl -k -s -o /dev/null -w "%%{http_code}" https://$${HARVESTER_URL}/ping)
        echo "Waiting for https://$${HARVESTER_URL}/ping - response: $${resp}"
        if [ "$${resp}" = "200" ]; then
          ((count++))
        fi
        sleep 2
      done
      EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      HARVESTER_URL = module.harvester_node.instances_public_ip[0]
    }
  }
}
