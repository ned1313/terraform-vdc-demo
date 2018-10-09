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
    RemoteIPAddress = "1.1.1.1"
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
  name                         = "${terraform.workspace}-vdc-pip"
  location                     = "${var.arm_region}"
  resource_group_name          = "${var.arm_resource_group_name}"
  public_ip_address_allocation = "dynamic"
}

#Create VNG subnet
resource "azurerm_subnet" "vng-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${var.arm_resource_group_name}"
  virtual_network_name = "${data.terraform_remote_state.network.}"
  address_prefix       = "${var.arm_gateway_subnet}"
}

#Create VNG  in Azure
resource "azurerm_virtual_network_gateway" "test" {
  name                = "test"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.test.id}"
  }

resource "azurerm_local_network_gateway" "onpremise" {
  name                = "onpremise"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  gateway_address     = "168.62.225.23"
  address_space       = ["10.1.1.0/24"]
}

#Create VNG Connection
resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.test.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.onpremise.id}"

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

#Create Winrm SG for Instance
resource "aws_security_group" "rras-sg" {
  # WinRM access from anywhere
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  subnet_id     = "${module.aws_vpc.public_subnet}"

  get_password_data = true

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = "${rsadecrypt(self.password_data, file(var.aws_key_file_path))}"
  }

  provisioner "remote-exec" {
    inline = [
      "${data.template_file.ec2-rras-script.rendered}",
    ]
  }

  user_data = <<EOF
<script>
  winrm quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
</script>
<powershell>
  netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
</powershell>
EOF
}

resource "aws_eip_association" "rras-eip-assoc" {
  instance_id   = "${aws_instance.rras.id}"
  allocation_id = "${aws_eip.rras-eip.id}"
}
