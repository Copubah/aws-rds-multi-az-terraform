#!/bin/bash
yum update -y

# Install MySQL client
yum install -y mysql

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Install SSM agent (usually pre-installed on Amazon Linux 2)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install useful tools
yum install -y htop wget curl telnet

# Create a simple script to test RDS connectivity
cat > /home/ec2-user/test-rds.sh << 'EOF'
#!/bin/bash
echo "Testing RDS connectivity..."
echo "Usage: ./test-rds.sh <rds-endpoint> <username> <password>"

if [ $# -ne 3 ]; then
    echo "Please provide RDS endpoint, username, and password"
    exit 1
fi

RDS_ENDPOINT=$1
USERNAME=$2
PASSWORD=$3

mysql -h $RDS_ENDPOINT -u $USERNAME -p$PASSWORD -e "SELECT 1 as test_connection;"
EOF

chmod +x /home/ec2-user/test-rds.sh
chown ec2-user:ec2-user /home/ec2-user/test-rds.sh

# Log completion
echo "EC2 instance setup completed for ${environment} environment" >> /var/log/user-data.log