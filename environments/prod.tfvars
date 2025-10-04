# Production Environment Configuration
environment = "prod"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr           = "10.1.0.0/16"
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets    = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# RDS Configuration
db_name                    = "proddb"
db_username                = "admin"
db_password                = "CHANGE_ME_SECURE_PASSWORD!" # Use AWS Secrets Manager or similar
db_instance_class          = "db.t3.small"                # Larger instance for production
db_allocated_storage       = 100
db_engine_version          = "8.0.35"
db_multi_az                = true # Multi-AZ for high availability
db_deletion_protection     = true # Protect against accidental deletion
db_backup_retention_period = 30   # 30 days backup retention

# Monitoring and Alerting
enable_monitoring = true
alert_email       = "prod-alerts@yourcompany.com" # Replace with your email

# Security - Restrictive for production
allowed_cidrs = ["10.1.0.0/16"] # Only VPC traffic

# EC2 Configuration
create_ec2_instance = true
ec2_instance_type   = "t3.small"
ec2_key_name        = "" # Add your key pair name if you want SSH access

# Tags
tags = {
  Project     = "RDS-MultiAZ-Failover"
  Environment = "prod"
  ManagedBy   = "Terraform"
  Owner       = "OpsTeam"
  CostCenter  = "Infrastructure"
}
