# VPC Module - Creates VPC with public/private subnets across multiple AZs
module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones

  tags = var.tags
}

# RDS Module - Multi-AZ MySQL with monitoring and security
module "rds" {
  source = "./modules/rds"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  # Database configuration
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  engine_version    = var.db_engine_version

  # Multi-AZ and security
  multi_az                = var.db_multi_az
  deletion_protection     = var.db_deletion_protection
  backup_retention_period = var.db_backup_retention_period

  # Monitoring and alerting
  enable_monitoring = var.enable_monitoring
  alert_email       = var.alert_email

  # Security
  allowed_cidrs = var.allowed_cidrs

  tags = var.tags
}

# EC2 Module - Optional bastion host for testing connectivity
module "ec2" {
  count = var.create_ec2_instance ? 1 : 0

  source = "./modules/ec2"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_ids[0]

  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  # Security group for RDS access
  rds_security_group_id = module.rds.security_group_id

  tags = var.tags
}
