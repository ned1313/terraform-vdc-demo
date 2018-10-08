##################################################################################
# VARIABLES
##################################################################################

#AWS Variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_network_address_space" {
  default = "10.1.0.0/16"
}
variable "aws_subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "aws_subnet2_address_space" {
  default = "10.1.1.0/24"
}

variable "aws_subnet_count" {
  default = "2"
}

variable "aws_key_file_path" {}

variable "aws_key_name" {
  
}


# Azure Variables
variable "arm_subscription" {}

variable "arm_appId" {}
variable "arm_tenant" {}
variable "arm_password" {}

variable "arm_region" {
  default = "eastus"
}

variable "arm_resource_group_name" {
    default = "vdc10112018"
}
variable "arm_network_address_space" {
  default = "10.2.0.0/16"
}
variable "arm_subnet1_address_space" {
  default = "10.2.0.0/24"
}
variable "arm_subnet2_address_space" {
  default = "10.2.1.0/24"
}

variable "arm_subnet_count" {
  default = "2"
}

#VPN variables
variable "vpn_shared_secret" {}

#Local variables



