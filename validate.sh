#!/bin/bash

# Validation script for AWS RDS Multi-AZ Terraform project
# This script validates the project structure and configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "AWS RDS Multi-AZ Project Validation"
echo "======================================"

# Check project structure
print_status "Checking project structure..."

required_files=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "provider.tf"
    "README.md"
    "Makefile"
    "deploy.sh"
    ".gitignore"
    "modules/vpc/main.tf"
    "modules/vpc/variables.tf"
    "modules/vpc/outputs.tf"
    "modules/rds/main.tf"
    "modules/rds/variables.tf"
    "modules/rds/outputs.tf"
    "modules/ec2/main.tf"
    "modules/ec2/variables.tf"
    "modules/ec2/outputs.tf"
    "modules/ec2/user_data.sh"
    "lambda/rds_health_check.py"
    "environments/dev.tfvars"
    "environments/prod.tfvars"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    print_success "All required files present"
else
    print_error "Missing files:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

# Check Terraform syntax
print_status "Validating Terraform syntax..."
if command -v terraform &> /dev/null; then
    if terraform fmt -check -recursive; then
        print_success "Terraform formatting is correct"
    else
        print_warning "Terraform files need formatting. Run: terraform fmt -recursive"
    fi
    
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform validation failed"
        exit 1
    fi
else
    print_warning "Terraform not installed, skipping syntax validation"
fi

# Check Python syntax
print_status "Validating Python Lambda function..."
if command -v python3 &> /dev/null; then
    if python3 -m py_compile lambda/rds_health_check.py; then
        print_success "Lambda function syntax is valid"
    else
        print_error "Lambda function has syntax errors"
        exit 1
    fi
else
    print_warning "Python3 not installed, skipping Lambda validation"
fi

# Check shell scripts
print_status "Validating shell scripts..."
if command -v shellcheck &> /dev/null; then
    scripts=("deploy.sh" "validate.sh" "modules/ec2/user_data.sh")
    for script in "${scripts[@]}"; do
        if shellcheck "$script"; then
            print_success "$script passed shellcheck"
        else
            print_warning "$script has shellcheck warnings"
        fi
    done
else
    print_warning "shellcheck not installed, skipping shell script validation"
fi

# Check environment files
print_status "Validating environment configurations..."

for env in dev prod; do
    tfvars_file="environments/${env}.tfvars"
    if [[ -f "$tfvars_file" ]]; then
        # Check for required variables
        required_vars=("environment" "db_password" "alert_email")
        missing_vars=()
        
        for var in "${required_vars[@]}"; do
            if ! grep -q "^${var}[[:space:]]*=" "$tfvars_file"; then
                missing_vars+=("$var")
            fi
        done
        
        if [[ ${#missing_vars[@]} -eq 0 ]]; then
            print_success "$tfvars_file has all required variables"
        else
            print_error "$tfvars_file missing variables: ${missing_vars[*]}"
        fi
        
        # Check for placeholder values
        if grep -q "CHANGE_ME" "$tfvars_file"; then
            print_warning "$tfvars_file contains placeholder values that need to be updated"
        fi
        
        if grep -q "yourcompany.com" "$tfvars_file"; then
            print_warning "$tfvars_file contains example email addresses"
        fi
    else
        print_error "$tfvars_file not found"
    fi
done

# Check AWS CLI configuration
print_status "Checking AWS CLI configuration..."
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials are configured and valid"
        aws sts get-caller-identity --output table
    else
        print_warning "AWS credentials not configured or invalid"
    fi
else
    print_warning "AWS CLI not installed"
fi

# Check for common security issues
print_status "Checking for security best practices..."

security_checks=0
security_warnings=0

# Check for hardcoded secrets
if grep -r "password.*=" . --include="*.tf" --exclude-dir=".terraform" | grep -v "var\." | grep -v "sensitive"; then
    print_warning "Potential hardcoded passwords found in Terraform files"
    ((security_warnings++))
fi

# Check for overly permissive CIDR blocks in RDS ingress rules (should be more restrictive)
if grep -r "0.0.0.0/0" modules/rds/ --include="*.tf" | grep "ingress" | grep -v "description.*MySQL access from allowed CIDRs"; then
    print_warning "Found overly permissive RDS ingress rules"
    ((security_warnings++))
fi

# Check for deletion protection
if grep -q "deletion_protection.*=.*false" environments/prod.tfvars; then
    print_warning "Deletion protection is disabled in production environment"
    ((security_warnings++))
fi

if [[ $security_warnings -eq 0 ]]; then
    print_success "No obvious security issues found"
else
    print_warning "Found $security_warnings potential security concerns (review above)"
fi

# Summary
echo ""
echo "Validation Summary"
echo "=================="

if [[ ${#missing_files[@]} -eq 0 ]]; then
    print_success "Project structure is complete"
else
    print_error "Missing required files"
fi

if command -v terraform &> /dev/null && terraform validate &> /dev/null; then
    print_success "Terraform configuration is valid"
else
    print_warning "Terraform validation skipped or failed"
fi

if [[ $security_warnings -eq 0 ]]; then
    print_success "No major security concerns"
else
    print_warning "$security_warnings security items to review"
fi

echo ""
print_status "Next steps:"
echo "1. Review any warnings above"
echo "2. Update placeholder values in tfvars files"
echo "3. Configure AWS credentials if not already done"
echo "4. Run: ./deploy.sh -e dev -a plan"

echo ""
print_success "Validation completed!"