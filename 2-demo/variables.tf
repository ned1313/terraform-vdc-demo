##################################################################################
# VARIABLES
##################################################################################

#AWS variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_network_address_space" {
  default = "10.1.0.0/16"
}
variable "aws_subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "aws_subnet2_address_space" {
  default = "10.1.1.0/24"
}

variable "aws_subnet_count" {
  default = "2"
}