# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-lesson5-bignichok"
#     key            = "lesson-6/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
