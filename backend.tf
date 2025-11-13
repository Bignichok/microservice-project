# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-microservice-project-bignichok"
#     key            = "microservice-project/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
