# Backend Configuration Examples
# 
# Uncomment and customize one of the following backend configurations:

# Option 1: S3 Backend with DynamoDB locking (Recommended for production)
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "rds-failover/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-locks"
#     encrypt        = true
#   }
# }

# Option 2: S3 Backend without locking (Basic setup)
# terraform {
#   backend "s3" {
#     bucket  = "your-terraform-state-bucket"
#     key     = "rds-failover/terraform.tfstate"
#     region  = "us-east-1"
#     encrypt = true
#   }
# }

# Option 3: Local backend (Development only - not recommended for production)
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# To set up S3 backend with DynamoDB locking, run these AWS CLI commands:
#
# 1. Create S3 bucket for state storage:
#    aws s3 mb s3://your-terraform-state-bucket --region us-east-1
#    aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
#    aws s3api put-bucket-encryption --bucket your-terraform-state-bucket --server-side-encryption-configuration '{
#      "Rules": [
#        {
#          "ApplyServerSideEncryptionByDefault": {
#            "SSEAlgorithm": "AES256"
#          }
#        }
#      ]
#    }'
#
# 2. Create DynamoDB table for state locking:
#    aws dynamodb create-table \
#      --table-name terraform-state-locks \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
#      --region us-east-1