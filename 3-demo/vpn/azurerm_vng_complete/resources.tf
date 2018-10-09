##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  subscription_id = "${var.arm_subscription}"
  client_id       = "${var.arm_appId}"
  client_secret   = "${var.arm_password}"
  tenant_id       = "${var.arm_tenant}"
}

##################################################################################
# RESOURCES
##################################################################################
#Create PIP
resource "azurerm_public_ip" "vng-pip" {
  name                         = "vdc-${terraform.workspace}-pip"
  location                     = "${var.arm_region}"
  resource_group_name          = "${var.arm_resource_group_name}"
  public_ip_address_allocation = "dynamic"
}

#Create VNG subnet
resource "azurerm_subnet" "vng-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${var.arm_resource_group_name}"
  virtual_network_name = "${var.arm_vnet_name}"
  address_prefix       = "${var.arm_gateway_subnet}"
}

#Create VNG  in Azure
resource "azurerm_virtual_network_gateway" "vng" {
  name                = "vdc-${terraform.workspace}-vng"
  location            = "${var.arm_region}"
  resource_group_name = "${var.arm_resource_group_name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.vng-pip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.vng-subnet.id}"
  }
}

data "azurerm_public_ip" "vng-pip" {
  name = "${azurerm_public_ip.vng-pip.name}"
  resource_group_name = "${var.arm_resource_group_name}"
}
