##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  subscription_id = "${var.arm_subscription}"
  client_id = "${var.arm_appId}"
  client_secret     = "${var.arm_password}"
  tenant_id = "${var.arm_tenant}"
}

##################################################################################
# RESOURCES
##################################################################################

resource "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
  location = "${var.arm_region}"
}


# NETWORKING #
module "vnet" {
    source              = "Azure/network/azurerm"
    resource_group_name = "${var.resource_group_name}"
    vnet_name = "Terraform-${terraform.workspace}"
    location            = "${var.arm_region}"
    address_space       = "${var.network_address_space}"
    subnet_prefixes     = ["${var.subnet1_address_space}","${var.subnet2_address_space}"]
    subnet_names        = ["subnet1", "subnet2"]

    tags                = {
                            environment = "vdc"
                          }
}