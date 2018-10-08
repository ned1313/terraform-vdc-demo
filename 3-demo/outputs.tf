output "ec2-rras-template" {
  value = "${data.template_file.ec2-rras-script.rendered}"
}

output "w2012r2-image" {
  value = "${data.aws_ami.w2012r2.name}"
}

