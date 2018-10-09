output "vng_pip" {
  value = "${data.azurerm_public_ip.vng-pip.ip_address}"
}

output "vng_id" {
  value = "${azurerm_virtual_network_gateway.vng.id}"
}



