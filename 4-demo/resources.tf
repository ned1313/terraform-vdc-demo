##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

provider "azurerm" {
  use_msi = true
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "vdc-${terraform.workspace}-vpc"

  cidr = "${var.aws_network_address_space}"
  azs = "${slice(data.aws_availability_zones.available.names,0,var.aws_subnet_count)}"
  private_subnets = "${data.template_file.private_cidrsubnet.*.rendered}"
  public_subnets = "${data.template_file.public_cidrsubnet.*.rendered}"

  enable_nat_gateway = false

  create_database_subnet_group = false

  
  tags {
    Environment = "${terraform.workspace}"
    Name = "4-demo-vpc"
  }
}

resource "azurerm_resource_group" "rg" {
  name = "${local.resource_group}"
  location = "${var.arm_region}"
}


# NETWORKING #
module "vnet" {
    source              = "Azure/network/azurerm"
    resource_group_name = "${local.resource_group}"
    vnet_name = "vdc-${terraform.workspace}-vnet"
    location            = "${var.arm_region}"
    address_space       = "${var.arm_network_address_space}"
    subnet_prefixes     = "${data.template_file.arm_cidrsubnet.*.rendered}"
    subnet_names        = "${data.template_file.arm_cidrsubnet_names.*.rendered}"

    tags                = {
                            environment = "${terraform.workspace}"
                          }
}
