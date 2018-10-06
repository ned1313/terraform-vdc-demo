terraform init --var-file="..\terraform.tfvars"
terraform plan --var-file="..\terraform.tfvars" -out 2-demo.tfplan
terraform apply 2-demo.tfplan
terraform destroy --var-file="..\terraform.tfvars" -auto-approve