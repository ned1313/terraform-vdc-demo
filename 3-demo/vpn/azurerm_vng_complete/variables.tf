# Azure Variables
variable "arm_subscription" {}

variable "arm_appId" {}
variable "arm_tenant" {}
variable "arm_password" {}

variable "arm_region" {
  default = "eastus"
}

variable "arm_resource_group_name" {}

variable "arm_gateway_subnet" {
  default = "10.2.2.0/24"
}

#VPN variables
variable "arm_vnet_name" {}
