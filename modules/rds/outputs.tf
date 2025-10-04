output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for RDS alerts"
  value       = aws_sns_topic.rds_alerts.arn
}

output "lambda_function_name" {
  description = "Lambda function name for RDS health checks"
  value       = aws_lambda_function.rds_health_check.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN for RDS health checks"
  value       = aws_lambda_function.rds_health_check.arn
}
