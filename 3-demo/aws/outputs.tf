##################################################################################
# OUTPUT
##################################################################################

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet" {
  value = "${module.vpc.public_subnets[0]}"
}

#EIP for EC2 RRAS
output "rras_eip" {
  value = "${aws_eip.rras-eip.public_ip}"
}

output "rras_id" {
  value = "${aws_eip.rras-eip.id}"
}
