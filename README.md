# AWS RDS Multi-AZ MySQL Deployment with Failover Monitoring

This Terraform project deploys a complete AWS RDS MySQL database with multi-AZ failover capabilities, including automated health monitoring and alerting system.

## Architecture Overview

- **VPC Module**: Creates VPC with public/private subnets across multiple AZs
- **RDS Module**: Multi-AZ MySQL database with enhanced monitoring, security groups, and parameter groups
- **EC2 Module**: Optional bastion host for database connectivity testing
- **Lambda Function**: Python-based health checker that runs every 5 minutes
- **SNS Topic**: Email notifications for database failover alerts
- **CloudWatch**: Monitoring, alarms, and EventBridge scheduling

## Features

- Multi-AZ RDS MySQL with automatic failover
- Enhanced monitoring with CloudWatch metrics and alarms
- Automated health checks via Lambda function every 5 minutes
- Email alerts for database connectivity issues
- Security best practices with VPC, security groups, and encryption
- Modular design for reusability across environments
- Multi-environment support (dev/staging/prod)
- Terraform 1.6+ compatibility with proper backend configuration  

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.6.0
3. **Python 3.11** (for Lambda function)
4. **Email address** for receiving alerts

### Required AWS Permissions

Your AWS credentials need the following permissions:
- VPC, Subnet, Route Table, Internet Gateway, NAT Gateway management
- RDS instance, subnet group, parameter group, option group management
- EC2 instance, security group, AMI management
- Lambda function, IAM role, CloudWatch Events management
- SNS topic and subscription management
- CloudWatch alarms and logs management

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/Copubah/aws-rds-multi-az-terraform.git
cd aws-rds-multi-az-terraform
```

### 2. Configure Backend (Optional but Recommended)

Edit `terraform.tf` and uncomment one of the backend configurations:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "rds-failover/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### 3. Customize Environment Variables

Edit the appropriate `.tfvars` file:

**For Development:**
```bash
cp environments/dev.tfvars.example environments/dev.tfvars
# Edit environments/dev.tfvars with your values
```

**For Production:**
```bash
cp environments/prod.tfvars.example environments/prod.tfvars
# Edit environments/prod.tfvars with your values
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment (development)
terraform plan -var-file="environments/dev.tfvars"

# Apply deployment
terraform apply -var-file="environments/dev.tfvars"
```

### 5. Test the Deployment

After deployment, you'll receive outputs including:
- RDS endpoint
- EC2 public IP (if created)
- SNS topic ARN

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev/staging/prod) | `dev` | Yes |
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `alert_email` | Email for RDS alerts | - | Yes |
| `db_password` | RDS master password | - | Yes |
| `db_multi_az` | Enable Multi-AZ deployment | `true` | No |
| `create_ec2_instance` | Create EC2 bastion host | `true` | No |

### Security Configuration

The project implements security best practices:

- Network Security: Private subnets for RDS, security groups with minimal access
- Encryption: RDS encryption at rest, EBS encryption for EC2
- Access Control: IAM roles with least privilege principles
- Monitoring: CloudWatch alarms for CPU, connections, and custom metrics

## Modules

### VPC Module (`modules/vpc/`)
- Creates VPC with DNS support
- Public and private subnets across multiple AZs
- Internet Gateway and NAT Gateways
- Route tables and associations

### RDS Module (`modules/rds/`)
- Multi-AZ MySQL RDS instance
- DB subnet group and security groups
- Parameter and option groups
- Enhanced monitoring and CloudWatch alarms
- Lambda health check function
- SNS topic for alerts

### EC2 Module (`modules/ec2/`)
- Optional bastion host in public subnet
- Security group allowing RDS access
- IAM role for CloudWatch and SSM
- User data script with MySQL client

## Monitoring and Alerting

### Lambda Health Check
- Runs every 5 minutes via EventBridge
- Tests database connectivity
- Checks RDS instance status
- Sends SNS alerts on failures

### CloudWatch Alarms
- CPU utilization > 80%
- Database connections > 50
- Custom metrics from Lambda

### SNS Notifications
Email alerts are sent for:
- Database connectivity failures
- High CPU utilization
- High connection count
- Lambda function errors

## Testing Database Connectivity

### From EC2 Instance

```bash
# SSH to EC2 instance
ssh -i your-key.pem ec2-user@<ec2-public-ip>

# Test RDS connectivity
./test-rds.sh <rds-endpoint> admin <password>
```

### From Lambda Function

The Lambda function automatically tests connectivity every 5 minutes. Check CloudWatch Logs:

```bash
aws logs tail /aws/lambda/<environment>-rds-health-check --follow
```

## Multi-Environment Deployment

### Development Environment
```bash
terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars"
```

### Production Environment
```bash
terraform workspace new prod
terraform apply -var-file="environments/prod.tfvars"
```

## Troubleshooting

### Common Issues

1. **Lambda Function Timeout**
   - Check VPC configuration and NAT Gateway
   - Verify security group rules

2. **RDS Connection Failures**
   - Verify security group allows port 3306
   - Check subnet group configuration
   - Validate credentials

3. **SNS Email Not Received**
   - Check email subscription confirmation
   - Verify SNS topic permissions

### Useful Commands

```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier <environment>-mysql-db

# Test Lambda function manually
aws lambda invoke --function-name <environment>-rds-health-check output.json

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda"
```

## Cost Optimization

### Development Environment
- Single AZ deployment (`db_multi_az = false`)
- Smaller instance types (`db.t3.micro`)
- Reduced backup retention (1 day)
- No deletion protection

### Production Environment
- Multi-AZ deployment for high availability
- Appropriate instance sizing
- Extended backup retention (30 days)
- Deletion protection enabled

## Security Best Practices

1. Use AWS Secrets Manager for database passwords in production
2. Enable VPC Flow Logs for network monitoring
3. Implement least privilege IAM policies
4. Enable AWS Config for compliance monitoring
5. Use AWS Systems Manager for secure EC2 access instead of SSH keys

## Cleanup

To destroy the infrastructure:

```bash
# Disable deletion protection first (if enabled)
terraform apply -var="db_deletion_protection=false" -var-file="environments/dev.tfvars"

# Destroy infrastructure
terraform destroy -var-file="environments/dev.tfvars"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Open an issue in the repository