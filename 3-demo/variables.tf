##################################################################################
# VARIABLES
##################################################################################

#AWS Variables
variable "aws_access_key" {}

variable "aws_secret_key" {}
variable "aws_key_file_path" {}
variable "aws_key_name" {}

variable "network_remote_state_bucket" {
  default = "vpcdemo10112018-remotestate"
}

variable "network_remote_state_key" {
  default = "2-demo.state"
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

#VPN variables
variable "vpn_shared_secret" {}

#Local variables
locals {
  workspace_key = "env:/${terraform.workspace}/${var.network_remote_state_key}"
}
