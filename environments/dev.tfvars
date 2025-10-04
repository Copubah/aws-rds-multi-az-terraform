# Development Environment Configuration
environment = "dev"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets     = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

# RDS Configuration
db_name                    = "devdb"
db_username                = "admin"
db_password                = "DevPassword123!"  # Change this in production!
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_engine_version          = "8.0.35"
db_multi_az                = false  # Single AZ for dev to save costs
db_deletion_protection     = false  # Allow deletion in dev
db_backup_retention_period = 1      # Minimal backup retention for dev

# Monitoring and Alerting
enable_monitoring = true
alert_email      = "dev-alerts@yourcompany.com"  # Replace with your email

# Security - More permissive for development
allowed_cidrs = ["10.0.0.0/16"]  # Only VPC traffic

# EC2 Configuration
create_ec2_instance = true
ec2_instance_type   = "t3.micro"
ec2_key_name        = ""  # Add your key pair name if you want SSH access

# Tags
tags = {
  Project     = "RDS-MultiAZ-Failover"
  Environment = "dev"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
}
