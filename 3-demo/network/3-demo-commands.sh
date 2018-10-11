terraform init --var-file="..\..\terraform.tfvars"
terraform workspace new v1
terraform plan --var-file="..\..\terraform.tfvars" -out 3-demo-network.tfplan
terraform apply 3-demo-network.tfplan
terraform destroy --var-file="..\..\terraform.tfvars" -auto-approve