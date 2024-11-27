locals {
  private_ssh_key_path = var.ssh_private_key_path == null ? "${path.cwd}/${var.prefix}-ssh_private_key.pem" : var.ssh_private_key_path
  public_ssh_key_path  = var.ssh_public_key_path == null ? "${path.cwd}/${var.prefix}-ssh_public_key.pem" : var.ssh_public_key_path
}

resource "tls_private_key" "ssh_private_key" {
  count     = var.create_ssh_key_pair ? 1 : 0
  algorithm = "ED25519"
}

resource "local_file" "private_key_pem" {
  count           = var.create_ssh_key_pair ? 1 : 0
  filename        = local.private_ssh_key_path
  content         = tls_private_key.ssh_private_key[0].private_key_openssh
  file_permission = "0600"
}

resource "local_file" "public_key_pem" {
  count           = var.create_ssh_key_pair ? 1 : 0
  filename        = local.public_ssh_key_path
  content         = tls_private_key.ssh_private_key[0].public_key_openssh
  file_permission = "0600"
}

resource "google_compute_network" "vpc" {
  count                   = var.create_vpc == true ? 1 : 0
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  depends_on = [resource.google_compute_firewall.default[0]]

  count         = var.create_vpc == true ? 1 : 0
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = var.vpc == null ? resource.google_compute_network.vpc[0].name : var.vpc
  ip_cidr_range = var.ip_cidr_range
}

resource "google_compute_firewall" "default" {
  count   = var.create_firewall ? 1 : 0
  name    = "${var.prefix}-firewall"
  network = var.vpc == null ? resource.google_compute_network.vpc[0].name : var.vpc

  allow {
    protocol = "icmp"
  }

  #https://docs.harvesterhci.io/v1.3/install/requirements#port-requirements-for-harvester-nodes
  allow {
    protocol = "tcp"
    ports    = ["2379", "2381", "2380", "10010", "6443", "9345", "10252", "10257", "10251", "10259", "10250", "10256", "10258", "9091", "9099", "2112", "6444", "10246-10249", "8181", "8444", "10245", "80", "9796", "30000-32767", "22", "3260"]
  }
  #https://docs.harvesterhci.io/v1.3/install/requirements#port-requirements-for-harvester-nodes
  allow {
    protocol = "udp"
    ports    = ["8472", "68"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8443", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}"]
}

data "google_compute_zones" "available" {
  region = var.region
}

resource "random_string" "random" {
  length  = 4
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "google_compute_instance" "default" {
  count        = var.instance_count
  name         = "${var.prefix}-vm-${count.index + 1}-${random_string.random.result}"
  machine_type = var.instance_type
  zone         = data.google_compute_zones.available.names[count.index % 3]

  tags = ["${var.prefix}"]

  boot_disk {
    initialize_params {
      size  = var.instance_disk_size
      type  = var.disk_type
      image = var.os_image
    }
  }

  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network    = var.vpc == null ? resource.google_compute_network.vpc[0].name : var.vpc
    subnetwork = var.subnet == null ? resource.google_compute_subnetwork.subnet[0].name : var.subnet
    access_config {}
  }

  metadata = {
    serial-port-logging-enable = "TRUE"
    ssh-keys                   = var.create_ssh_key_pair ? "${var.ssh_username}:${tls_private_key.ssh_private_key[0].public_key_openssh}" : "${var.ssh_username}:${local.public_ssh_key_path}"
    startup-script             = var.startup_script
  }

  advanced_machine_features {
    enable_nested_virtualization = var.nested_virtualization
  }
}
