# AWS RDS Multi-AZ Failover Project Overview

## Project Summary

This Terraform project creates a production-ready AWS RDS MySQL database with multi-AZ failover capabilities, complete with automated health monitoring, alerting, and a comprehensive testing infrastructure.

## Architecture Components

### Core Infrastructure
- VPC: Multi-AZ VPC with public/private subnets, NAT gateways, and proper routing
- RDS: Multi-AZ MySQL 8.0 with enhanced monitoring, encryption, and automated backups
- EC2: Optional bastion host for database connectivity testing
- Lambda: Python-based health checker with VPC connectivity
- SNS: Email notification system for alerts
- CloudWatch: Comprehensive monitoring, alarms, and log management

### Security Features
- VPC with private subnets for database isolation
- Security groups with least-privilege access
- RDS encryption at rest and in transit
- IAM roles with minimal required permissions
- No hardcoded credentials (parameterized)
- CloudWatch logging for audit trails

### High Availability Features
- Multi-AZ RDS deployment for automatic failover
- Automated health checks every 5 minutes
- Real-time alerting via SNS/email
- Enhanced monitoring with Performance Insights
- Automated backups with configurable retention

## Project Structure

```
.
├── main.tf                     # Root module configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── provider.tf                 # Provider and backend configuration
├── terraform.tf                # Backend configuration examples
├── README.md                   # Comprehensive documentation
├── Makefile                    # Automation commands
├── deploy.sh                   # Deployment script
├── validate.sh                 # Validation script
├── .gitignore                  # Git ignore rules
├── PROJECT_OVERVIEW.md         # This file
├── environments/
│   ├── dev.tfvars             # Development environment config
│   └── prod.tfvars            # Production environment config
├── modules/
│   ├── vpc/                   # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/                   # RDS module with monitoring
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/                   # EC2 bastion host module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── user_data.sh
└── lambda/
    └── rds_health_check.py    # Lambda health check function
```

## Quick Start Guide

### Prerequisites
1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.6.0 installed
3. Python 3.11+ for Lambda function
4. Valid email address for alerts

### Deployment Steps

1. **Clone and Setup**
   ```bash
   git clone <repository>
   cd terraform-rds-failover
   ```

2. **Validate Project**
   ```bash
   ./validate.sh
   ```

3. **Configure Environment**
   ```bash
   # Edit environments/dev.tfvars with your values
   vim environments/dev.tfvars
   ```

4. **Deploy Infrastructure**
   ```bash
   # Using deployment script
   ./deploy.sh -e dev -a plan
   ./deploy.sh -e dev -a apply
   
   # Or using Makefile
   make plan ENV=dev
   make apply ENV=dev
   ```

5. **Verify Deployment**
   - Check email for SNS subscription confirmation
   - Monitor CloudWatch logs for Lambda execution
   - Test RDS connectivity from EC2 instance

## Configuration Options

### Environment Variables (tfvars)

| Variable | Description | Dev Default | Prod Default |
|----------|-------------|-------------|--------------|
| `environment` | Environment name | `dev` | `prod` |
| `db_multi_az` | Multi-AZ deployment | `false` | `true` |
| `db_instance_class` | RDS instance type | `db.t3.micro` | `db.t3.small` |
| `db_deletion_protection` | Deletion protection | `false` | `true` |
| `db_backup_retention_period` | Backup retention days | `1` | `30` |
| `create_ec2_instance` | Create bastion host | `true` | `true` |
| `alert_email` | Email for alerts | Required | Required |

### Security Configuration

- **Network**: Private subnets for RDS, restricted security groups
- **Encryption**: RDS encryption at rest, EBS encryption for EC2
- **Access**: IAM roles with least privilege, no hardcoded credentials
- **Monitoring**: CloudWatch logs, Performance Insights, enhanced monitoring

## Monitoring and Alerting

### Lambda Health Checks
- **Frequency**: Every 5 minutes via EventBridge
- **Tests**: Database connectivity, query execution, RDS status
- **Alerts**: SNS notifications on failures
- **Logging**: CloudWatch logs with detailed error information

### CloudWatch Alarms
- **CPU Utilization**: Alert when > 80%
- **Database Connections**: Alert when > 50 connections
- **Custom Metrics**: Lambda execution failures

### SNS Notifications
Email alerts are sent for:
- Database connectivity failures
- High resource utilization
- Lambda function errors
- RDS instance status changes

## Management Commands

### Using Makefile
```bash
make help                    # Show all available commands
make plan ENV=dev           # Plan deployment
make apply ENV=prod         # Apply deployment
make destroy ENV=dev        # Destroy environment
make validate               # Validate configuration
make clean                  # Clean temporary files
```

### Using Deployment Script
```bash
./deploy.sh -h              # Show help
./deploy.sh -e dev -a plan  # Plan dev deployment
./deploy.sh -e prod -a apply -y  # Apply prod with auto-approve
./deploy.sh -e dev -a destroy    # Destroy dev environment
```

## Testing and Validation

### Automated Testing
```bash
./validate.sh              # Run full project validation
make test-lambda           # Test Lambda function syntax
make lint                  # Run linting checks
```

### Manual Testing
```bash
# Test RDS connectivity from EC2
ssh -i key.pem ec2-user@<ec2-ip>
./test-rds.sh <rds-endpoint> admin <password>

# Test Lambda function
aws lambda invoke --function-name dev-rds-health-check output.json

# Check CloudWatch logs
aws logs tail /aws/lambda/dev-rds-health-check --follow
```

## Cost Optimization

### Development Environment
- Single AZ deployment (saves ~50% on RDS costs)
- Smaller instance types (`t3.micro`)
- Minimal backup retention (1 day)
- No deletion protection

### Production Environment
- Multi-AZ for high availability
- Appropriate instance sizing
- Extended backup retention (30 days)
- Deletion protection enabled

### Estimated Monthly Costs (us-east-1)
- **Dev Environment**: ~$25-35/month
- **Prod Environment**: ~$60-80/month

*Costs include RDS, EC2, Lambda, CloudWatch, and data transfer*

## Security Best Practices

### Implemented Security Measures
- VPC isolation with private subnets
- Security groups with minimal access
- Encryption at rest and in transit
- IAM roles with least privilege
- No hardcoded credentials
- CloudWatch logging for audit

### Additional Recommendations
- Use AWS Secrets Manager for database passwords
- Enable VPC Flow Logs for network monitoring
- Implement AWS Config for compliance
- Use AWS Systems Manager for secure EC2 access
- Enable AWS GuardDuty for threat detection

## Troubleshooting

### Common Issues

1. **Lambda Timeout**
   - Check VPC configuration and NAT Gateway
   - Verify security group rules allow outbound traffic

2. **RDS Connection Failures**
   - Verify security group allows port 3306
   - Check subnet group spans multiple AZs
   - Validate database credentials

3. **SNS Email Not Received**
   - Check email subscription confirmation
   - Verify SNS topic permissions
   - Check spam folder

### Useful Commands
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier dev-mysql-db

# View Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda"

# Test SNS topic
aws sns publish --topic-arn <topic-arn> --message "Test message"
```

## Scaling and Extensions

### Horizontal Scaling
- Add read replicas for read-heavy workloads
- Implement connection pooling (RDS Proxy)
- Use Application Load Balancer for multi-AZ applications

### Vertical Scaling
- Upgrade RDS instance class as needed
- Increase allocated storage with auto-scaling
- Optimize database parameters for workload

### Additional Features
- Implement blue/green deployments
- Add cross-region backup replication
- Integrate with AWS Backup for centralized backup management
- Add custom CloudWatch dashboards

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper testing
4. Update documentation
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs and metrics
3. Validate configuration with `./validate.sh`
4. Open an issue in the repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated**: January 2025  
**Terraform Version**: >= 1.6.0  
**AWS Provider Version**: ~> 5.0