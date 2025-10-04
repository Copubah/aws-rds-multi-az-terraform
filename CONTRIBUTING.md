# Contributing to AWS RDS Multi-AZ Terraform Project

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Issues

Before creating an issue, please:
1. Check existing issues to avoid duplicates
2. Use the issue template if available
3. Provide clear reproduction steps
4. Include relevant system information (Terraform version, AWS region, etc.)

### Submitting Changes

1. **Fork the repository**
   ```bash
   gh repo fork Copubah/aws-rds-multi-az-terraform
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards outlined below
   - Add tests if applicable
   - Update documentation as needed

4. **Test your changes**
   ```bash
   ./validate.sh
   terraform fmt -recursive
   terraform validate
   ```

5. **Commit your changes**
   ```bash
   git commit -m "feat: add new feature description"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Use a clear title and description
   - Reference any related issues
   - Include testing information

## Development Guidelines

### Terraform Standards

- **Formatting**: Use `terraform fmt` to format all `.tf` files
- **Validation**: Ensure `terraform validate` passes
- **Variables**: Use descriptive names and include descriptions
- **Outputs**: Document all outputs with descriptions
- **Comments**: Add comments for complex logic

### Module Structure

```
modules/
├── module-name/
│   ├── main.tf          # Main resources
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   └── README.md        # Module documentation
```

### Security Guidelines

- Never commit sensitive information (passwords, keys, etc.)
- Use variables for all configurable values
- Follow least-privilege principles for IAM roles
- Enable encryption where applicable
- Use security groups with minimal required access

### Documentation Standards

- Update README.md for significant changes
- Document new variables and outputs
- Include examples for new features
- Update CHANGELOG.md following semantic versioning

### Testing Requirements

Before submitting a PR, ensure:
- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes
- [ ] `./validate.sh` passes without errors
- [ ] Python syntax check passes for Lambda functions
- [ ] Documentation is updated
- [ ] Examples work as documented

## Project Structure

```
.
├── main.tf                     # Root module
├── variables.tf                # Root variables
├── outputs.tf                  # Root outputs
├── provider.tf                 # Provider configuration
├── terraform.tf                # Backend configuration
├── environments/               # Environment-specific configs
│   ├── dev.tfvars
│   └── prod.tfvars
├── modules/                    # Reusable modules
│   ├── vpc/
│   ├── rds/
│   └── ec2/
├── lambda/                     # Lambda functions
├── .github/                    # GitHub workflows
├── docs/                       # Additional documentation
└── scripts/                    # Utility scripts
```

## Commit Message Format

Use conventional commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(rds): add support for MySQL 8.0.36
fix(lambda): handle connection timeout gracefully
docs(readme): update deployment instructions
```

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md with new features and fixes
3. Create a release PR
4. Tag the release after merging
5. Update documentation if needed

## Getting Help

- Check existing documentation first
- Search closed issues for similar problems
- Create a new issue with detailed information
- Join discussions in existing issues

## Local Development Setup

1. **Prerequisites**
   ```bash
   # Install required tools
   terraform --version  # >= 1.6.0
   aws --version        # AWS CLI v2
   python3 --version    # >= 3.11
   ```

2. **Clone and setup**
   ```bash
   git clone https://github.com/Copubah/aws-rds-multi-az-terraform.git
   cd aws-rds-multi-az-terraform
   ```

3. **Validate setup**
   ```bash
   ./validate.sh
   ```

4. **Test changes**
   ```bash
   # Format code
   terraform fmt -recursive
   
   # Validate configuration
   terraform validate
   
   # Plan deployment (optional)
   terraform plan -var-file="environments/dev.tfvars"
   ```

## Common Development Tasks

### Adding a New Module

1. Create module directory structure
2. Implement main.tf, variables.tf, outputs.tf
3. Add module documentation
4. Update root module to use new module
5. Add tests and examples
6. Update main README.md

### Modifying Existing Resources

1. Make changes in appropriate module
2. Update variable descriptions if needed
3. Test with both dev and prod configurations
4. Update documentation
5. Verify backward compatibility

### Adding New Environment

1. Create new .tfvars file in environments/
2. Update validation scripts
3. Add environment-specific documentation
4. Test deployment process

## Questions?

If you have questions about contributing, please:
1. Check this document first
2. Look at existing issues and PRs
3. Create a new issue with the "question" label

Thank you for contributing to make this project better!