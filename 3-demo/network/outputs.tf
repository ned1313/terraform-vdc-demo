##################################################################################
# OUTPUT
##################################################################################

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vnet_name" {
  value = "${module.vnet.vnet_name}"
}

output "vpc_cidr" {
  value = "${module.vpc.vpc_cidr_block}"
}

output "vpc_public_subnets" {
  value = "${module.vpc.public_subnets}"
}

output "vnet_cidr" {
  value = "${module.vnet.vnet_address_space}"
}


