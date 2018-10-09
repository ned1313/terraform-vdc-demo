output "ec2-rras-template" {
  value = "${data.template_file.ec2-rras-script.rendered}"
}

output "w2012r2-image" {
  value = "${data.aws_ami.w2012r2.name}"
}

output "vng-pip-name" {
  value = "${module.azurerm_vng_complete.vng_pip_name}"
}

output "vng-pip-address" {
  value = "${data.azurerm_public_ip.vng-pip.ip_address}"
}

