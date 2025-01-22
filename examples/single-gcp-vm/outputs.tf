output "instances_private_ip" {
  #value = concat([module.harvester_first_node.instances_private_ip], [module.harvester_additional_nodes.instances_private_ip])
  value = module.harvester_first_node.instances_private_ip
}

output "instances_public_ip" {
  #value = concat([module.harvester_first_node.instances_public_ip], [module.harvester_additional_nodes.instances_public_ip])
  value = module.harvester_first_node.instances_public_ip
}
