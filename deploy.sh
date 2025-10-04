#!/bin/bash

# AWS RDS Multi-AZ Deployment Script
# This script helps deploy the Terraform infrastructure with proper validation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
ACTION="plan"
AUTO_APPROVE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "AWS RDS Multi-AZ Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Environment to deploy (dev|prod) [default: dev]"
    echo "  -a, --action ACTION      Action to perform (plan|apply|destroy) [default: plan]"
    echo "  -y, --auto-approve       Auto approve apply/destroy operations"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev -a plan                    # Plan dev deployment"
    echo "  $0 -e prod -a apply -y               # Apply prod deployment with auto-approve"
    echo "  $0 -e dev -a destroy                 # Destroy dev environment"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -y|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'dev' or 'prod'"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION. Must be 'plan', 'apply', or 'destroy'"
    exit 1
fi

print_status "Starting deployment script..."
print_status "Environment: $ENVIRONMENT"
print_status "Action: $ACTION"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid"
    exit 1
fi

print_success "Prerequisites check passed"

# Check if tfvars file exists
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"
if [[ ! -f "$TFVARS_FILE" ]]; then
    print_error "Environment file not found: $TFVARS_FILE"
    print_warning "Please create the file with required variables"
    exit 1
fi

# Validate required variables in tfvars
print_status "Validating environment configuration..."

required_vars=("environment" "db_password" "alert_email")
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}[[:space:]]*=" "$TFVARS_FILE"; then
        print_error "Required variable '$var' not found in $TFVARS_FILE"
        exit 1
    fi
done

# Check for placeholder values that need to be changed
if grep -q "CHANGE_ME" "$TFVARS_FILE"; then
    print_error "Found placeholder values in $TFVARS_FILE. Please update all CHANGE_ME values."
    exit 1
fi

if grep -q "yourcompany.com" "$TFVARS_FILE"; then
    print_warning "Found example email addresses in $TFVARS_FILE. Please update with real email addresses."
fi

print_success "Environment configuration validated"

# Initialize Terraform if needed
if [[ ! -d ".terraform" ]]; then
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
fi

# Create Lambda ZIP file if it doesn't exist
if [[ ! -f "lambda/lambda.zip" ]]; then
    print_status "Creating Lambda deployment package..."
    if [[ -f "lambda/rds_health_check.py" ]]; then
        cd lambda
        zip lambda.zip rds_health_check.py
        cd ..
        print_success "Lambda package created"
    else
        print_error "Lambda function file not found: lambda/rds_health_check.py"
        exit 1
    fi
fi

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform configuration validation failed"
    exit 1
fi

# Perform the requested action
case $ACTION in
    plan)
        print_status "Creating Terraform plan..."
        terraform plan -var-file="$TFVARS_FILE" -out="${ENVIRONMENT}.tfplan"
        print_success "Plan created successfully: ${ENVIRONMENT}.tfplan"
        print_warning "Review the plan above before applying"
        ;;
    
    apply)
        # Check if plan exists
        if [[ -f "${ENVIRONMENT}.tfplan" ]]; then
            print_status "Applying existing plan: ${ENVIRONMENT}.tfplan"
            if [[ "$AUTO_APPROVE" == true ]]; then
                terraform apply "${ENVIRONMENT}.tfplan"
            else
                terraform apply "${ENVIRONMENT}.tfplan"
            fi
        else
            print_status "No existing plan found. Creating and applying..."
            if [[ "$AUTO_APPROVE" == true ]]; then
                terraform apply -var-file="$TFVARS_FILE" -auto-approve
            else
                terraform apply -var-file="$TFVARS_FILE"
            fi
        fi
        
        # Clean up plan file
        rm -f "${ENVIRONMENT}.tfplan"
        
        print_success "Deployment completed successfully!"
        print_status "Getting outputs..."
        terraform output
        ;;
    
    destroy)
        print_warning "This will destroy all resources in the $ENVIRONMENT environment!"
        
        if [[ "$AUTO_APPROVE" != true ]]; then
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                print_status "Destroy operation cancelled"
                exit 0
            fi
        fi
        
        print_status "Destroying infrastructure..."
        if [[ "$AUTO_APPROVE" == true ]]; then
            terraform destroy -var-file="$TFVARS_FILE" -auto-approve
        else
            terraform destroy -var-file="$TFVARS_FILE"
        fi
        
        print_success "Infrastructure destroyed successfully"
        ;;
esac

print_success "Script completed successfully!"

# Show next steps based on action
case $ACTION in
    plan)
        echo ""
        print_status "Next steps:"
        echo "  1. Review the plan output above"
        echo "  2. Run: $0 -e $ENVIRONMENT -a apply"
        ;;
    apply)
        echo ""
        print_status "Next steps:"
        echo "  1. Check your email for SNS subscription confirmation"
        echo "  2. Test RDS connectivity using the EC2 instance (if created)"
        echo "  3. Monitor CloudWatch logs for Lambda function execution"
        echo "  4. Set up additional monitoring as needed"
        ;;
    destroy)
        echo ""
        print_status "Environment $ENVIRONMENT has been destroyed"
        ;;
esac