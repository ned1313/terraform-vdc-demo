##################################################################################
# VARIABLES
##################################################################################
variable "arm_subscription" {}

variable "arm_appId" {}
variable "arm_tenant" {}
variable "arm_password" {}

variable "arm_region" {
  default = "eastus"
}

variable "resource_group_name" {
    default = "vdc10112018"
}
variable "network_address_space" {
  default = "10.2.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.2.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.2.1.0/24"
}

variable "subnet_count" {
  default = "2"
}