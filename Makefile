# Terraform RDS Multi-AZ Deployment Makefile

.PHONY: help init plan apply destroy validate fmt lint clean dev prod

# Default environment
ENV ?= dev

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)AWS RDS Multi-AZ Terraform Deployment$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> [ENV=dev|prod]"
	@echo ""
	@echo "$(YELLOW)Targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make init                    # Initialize Terraform"
	@echo "  make plan ENV=dev           # Plan dev deployment"
	@echo "  make apply ENV=prod         # Apply prod deployment"
	@echo "  make destroy ENV=dev        # Destroy dev environment"

init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)✓ Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(NC)"

plan: validate ## Plan Terraform deployment
	@echo "$(BLUE)Planning deployment for $(ENV) environment...$(NC)"
	@if [ ! -f "environments/$(ENV).tfvars" ]; then \
		echo "$(RED)Error: environments/$(ENV).tfvars not found$(NC)"; \
		exit 1; \
	fi
	terraform plan -var-file="environments/$(ENV).tfvars" -out="$(ENV).tfplan"
	@echo "$(GREEN)✓ Plan created: $(ENV).tfplan$(NC)"

apply: ## Apply Terraform deployment
	@echo "$(BLUE)Applying deployment for $(ENV) environment...$(NC)"
	@if [ ! -f "$(ENV).tfplan" ]; then \
		echo "$(YELLOW)No plan file found. Creating plan first...$(NC)"; \
		$(MAKE) plan ENV=$(ENV); \
	fi
	terraform apply "$(ENV).tfplan"
	@rm -f "$(ENV).tfplan"
	@echo "$(GREEN)✓ Deployment completed for $(ENV)$(NC)"

destroy: ## Destroy Terraform deployment
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	@echo "$(BLUE)Destroying $(ENV) environment...$(NC)"
	terraform destroy -var-file="environments/$(ENV).tfvars" -auto-approve
	@echo "$(GREEN)✓ Environment $(ENV) destroyed$(NC)"

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENV):$(NC)"
	terraform output

state: ## Show Terraform state list
	@echo "$(BLUE)Terraform state resources:$(NC)"
	terraform state list

refresh: ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state...$(NC)"
	terraform refresh -var-file="environments/$(ENV).tfvars"
	@echo "$(GREEN)✓ State refreshed$(NC)"

clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	rm -f *.tfplan
	rm -f lambda/lambda.zip
	@echo "$(GREEN)✓ Temporary files cleaned$(NC)"

lint: ## Run terraform and shell linting
	@echo "$(BLUE)Running linting checks...$(NC)"
	terraform fmt -check -recursive
	@if command -v tflint >/dev/null 2>&1; then \
		echo "Running tflint..."; \
		tflint; \
	else \
		echo "$(YELLOW)tflint not installed, skipping...$(NC)"; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		find . -name "*.sh" -exec shellcheck {} \;; \
	else \
		echo "$(YELLOW)shellcheck not installed, skipping...$(NC)"; \
	fi
	@echo "$(GREEN)✓ Linting completed$(NC)"

dev: ## Quick deploy to dev environment
	@$(MAKE) plan ENV=dev
	@$(MAKE) apply ENV=dev

prod: ## Quick deploy to prod environment
	@$(MAKE) plan ENV=prod
	@$(MAKE) apply ENV=prod

test-lambda: ## Test Lambda function locally
	@echo "$(BLUE)Testing Lambda function...$(NC)"
	@if [ -f "lambda/rds_health_check.py" ]; then \
		python3 -m py_compile lambda/rds_health_check.py; \
		echo "$(GREEN)✓ Lambda function syntax is valid$(NC)"; \
	else \
		echo "$(RED)Error: Lambda function not found$(NC)"; \
		exit 1; \
	fi

check-aws: ## Check AWS credentials and permissions
	@echo "$(BLUE)Checking AWS credentials...$(NC)"
	@aws sts get-caller-identity
	@echo "$(GREEN)✓ AWS credentials are valid$(NC)"

setup-backend: ## Setup S3 backend and DynamoDB table
	@echo "$(BLUE)Setting up Terraform backend...$(NC)"
	@read -p "Enter S3 bucket name for Terraform state: " bucket; \
	read -p "Enter AWS region (default: us-east-1): " region; \
	region=$${region:-us-east-1}; \
	echo "Creating S3 bucket: $$bucket"; \
	aws s3 mb s3://$$bucket --region $$region || true; \
	aws s3api put-bucket-versioning --bucket $$bucket --versioning-configuration Status=Enabled; \
	aws s3api put-bucket-encryption --bucket $$bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'; \
	echo "Creating DynamoDB table: terraform-state-locks"; \
	aws dynamodb create-table \
		--table-name terraform-state-locks \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
		--region $$region || true; \
	echo "$(GREEN)✓ Backend setup completed$(NC)"; \
	echo "$(YELLOW)Update terraform.tf with your bucket name and region$(NC)"

docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README-terraform.md .; \
		echo "$(GREEN)✓ Documentation generated: README-terraform.md$(NC)"; \
	else \
		echo "$(YELLOW)terraform-docs not installed, skipping...$(NC)"; \
		echo "Install with: go install github.com/terraform-docs/terraform-docs@latest"; \
	fi

# Environment-specific shortcuts
dev-plan: ## Plan dev environment
	@$(MAKE) plan ENV=dev

dev-apply: ## Apply dev environment
	@$(MAKE) apply ENV=dev

dev-destroy: ## Destroy dev environment
	@$(MAKE) destroy ENV=dev

prod-plan: ## Plan prod environment
	@$(MAKE) plan ENV=prod

prod-apply: ## Apply prod environment
	@$(MAKE) apply ENV=prod

prod-destroy: ## Destroy prod environment
	@$(MAKE) destroy ENV=prod