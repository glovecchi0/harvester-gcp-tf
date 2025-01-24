output "first_instance_private_ip" {
  value = module.harvester_first_node.instances_private_ip
}

output "additional_instances_private_ips" {
  value = module.harvester_additional_nodes.instances_private_ip
}

output "first_instance_public_ip" {
  value = module.harvester_first_node.instances_public_ip
}

output "additional_instances_public_ips" {
  value = module.harvester_additional_nodes.instances_public_ip
}
