terraform init --var-file="..\terraform.tfvars"
terraform plan --var-file="..\terraform.tfvars" -out 3-demo.tfplan
terraform apply 3-demo.tfplan
terraform destroy --var-file="..\terraform.tfvars" -auto-approve