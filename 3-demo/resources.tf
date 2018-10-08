##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

##################################################################################
# DATA
##################################################################################

#Create template from RRASConfig.ps1 file
data "template_file" "ec2-rras-script" {
  template = "${file("RRASConfig.ps1")}"

  vars {
      RemoteIPAddress = "1.1.1.1"
      RemoteSubnet = "${var.arm_network_address_space}"
      ShareSecret = "${var.vpn_shared_secret}"
  }
}

#Get Windows Server 2012R2 AMI
data "aws_ami" "w2012r2" {
  most_recent = true

  filter {
      name = "owner-alias"
      values = ["amazon"]
  }

  filter {
      name = "name"
      values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base-*"]
  }
}

##################################################################################
# RESOURCES
##################################################################################
#Invoke AWS Module
module "aws_vpc" {
  source = ".\\aws"

  aws_access_key = "${var.aws_access_key}"

  aws_secret_key = "${var.aws_secret_key}"
  
}

#Invoke the Azure Module
module "azurerm_vnet" {
  source = ".\\azure"

  arm_subscription = "${var.arm_subscription}"

  arm_appId = "${var.arm_appId}"

  arm_tenant = "${var.arm_tenant}"

  arm_password = "${var.arm_password}"
  
}


#Create VPN connection in Azure


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
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
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
  ami = "${data.aws_ami.w2012r2.image_id}"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  subnet_id = "${module.aws_vpc.public_subnet}"

  get_password_data = true

  connection {
    type = "winrm"
    user = "Administrator"
    password = "${rsadecrypt(self.password_data, file(var.aws_key_file_path))}"
  }
  provisioner "remote-exec" {
    inline = [
      "${data.template_file.ec2-rras-script.rendered}"
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
  instance_id = "${aws_instance.rras.id}"
  allocation_id = "${module.aws_vpc.rras_id}"
}



