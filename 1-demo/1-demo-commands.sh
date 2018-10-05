terraform init
terraform plan --var-file="..\terraform.tfvars" -out 1-demo.tfplan
terraform apply 1-demo.tfplan
terraform destroy --var-file="..\terraform.tfvars"