# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

# SNS Topic Output
output "sns_topic_arn" {
  description = "ARN of SNS topic for RDS alerts"
  value       = module.rds.sns_topic_arn
}

# EC2 Outputs (conditional)
output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = var.create_ec2_instance ? module.ec2[0].public_ip : null
}

output "ec2_instance_id" {
  description = "ID of EC2 instance"
  value       = var.create_ec2_instance ? module.ec2[0].instance_id : null
}

# Lambda Function Output
output "lambda_function_name" {
  description = "Name of the Lambda function for RDS health checks"
  value       = module.rds.lambda_function_name
}
