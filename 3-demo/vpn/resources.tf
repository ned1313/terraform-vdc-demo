##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

provider "azurerm" {
  subscription_id = "${var.arm_subscription}"
  client_id       = "${var.arm_appId}"
  client_secret   = "${var.arm_password}"
  tenant_id       = "${var.arm_tenant}"
}

##################################################################################
# DATA
##################################################################################

#Create template from RRASConfig.ps1 file
data "template_file" "ec2-rras-script" {
  template = "${file("RRASConfig.ps1")}"

  vars {
    RemoteIPAddress = "${azurerm_public_ip.vng-pip.ip_address}"
    RemoteSubnet    = "${var.arm_network_address_space}"
    ShareSecret     = "${var.vpn_shared_secret}"
  }
}

#Get Windows Server 2012R2 AMI
data "aws_ami" "w2012r2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base-*"]
  }
}

#Get info from network state
data "terraform_remote_state" "network" {
  backend = "s3"

  config {
    key        = "${terraform.workspace == "default" ? var.network_remote_state_key : local.workspace_key}"
    bucket     = "${var.network_remote_state_bucket}"
    region     = "us-east-1"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
  }
}

##################################################################################
# RESOURCES
##################################################################################
#Create EIP
resource "aws_eip" "rras-eip" {}

#Create PIP
resource "azurerm_public_ip" "vng-pip" {
  name                         = "vdc-${terraform.workspace}-pip"
  location                     = "${var.arm_region}"
  resource_group_name          = "${local.resource_group}"
  public_ip_address_allocation = "dynamic"
}

#Create VNG subnet
resource "azurerm_subnet" "vng-subnet" {
  name                 = "vdc-${terraform.workspace}-GatewaySubnet"
  resource_group_name  = "${local.resource_group}"
  virtual_network_name = "${data.terraform_remote_state.network.vnet_name}"
  address_prefix       = "${var.arm_gateway_subnet}"
}

#Create VNG  in Azure
resource "azurerm_virtual_network_gateway" "vng" {
  name                = "vdc-${terraform.workspace}-vng"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${local.resource_group}"

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

resource "azurerm_local_network_gateway" "aws" {
  name                = "aws"
  location            = "${var.arm_region}"
  resource_group_name = "${local.resource_group}"
  gateway_address     = "${aws_eip.public_ip}"
  address_space       = ["${data.terraform_remote_state.network.vpc_cidr}"]
}

#Create VNG Connection
resource "azurerm_virtual_network_gateway_connection" "azure-aws" {
  name                = "azure-aws"
  location            = "${var.arm_region}"
  resource_group_name = "${local.resource_group}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.aws.id}"

  shared_key = "${var.vpn_shared_secret}"
}

#Create Winrm SG for Instance
resource "aws_security_group" "rras-sg" {

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create EC2 instance for RRAS
resource "aws_instance" "rras" {
  ami           = "${data.aws_ami.w2012r2.image_id}"
  instance_type = "t2.micro"
  key_name      = "${var.aws_key_name}"
  subnet_id     = "${data.terraform_remote_state.network.vpc_public_subnets[0]}"

  user_data = "${data.template_file.ec2-rras-script.rendered}"

}

resource "aws_eip_association" "rras-eip-assoc" {
  instance_id   = "${aws_instance.rras.id}"
  allocation_id = "${aws_eip.rras-eip.id}"
}