# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SuperClaude** is a template-based infrastructure management system designed to manage Azure and AWS environments through CLI operations, integrated with Claude Skills for automated workflows.

### Core Objectives
- Provide reusable templates for Azure and AWS infrastructure provisioning and management
- Enable Claude Skills to execute infrastructure operations generically using templates
- Use LocalStack for local AWS development and testing
- Support CLI-based configuration management for both cloud providers

## Architecture

### Template System
Templates define infrastructure configurations and operations for both Azure and AWS. Each template should:
- Define resource configurations in a declarative format
- Support parameterization for reusability
- Include validation rules for inputs
- Provide CLI command generation logic

### Claude Skills Integration
Skills invoke templates to perform operations:
- Skills parse user intent and map to appropriate templates
- Templates generate CLI commands (Azure CLI, AWS CLI)
- Commands execute against target environments (production clouds or LocalStack)
- Results are captured and returned to Claude

### Environment Targeting
- **Azure**: Direct Azure CLI commands to Azure subscriptions
- **AWS Production**: AWS CLI commands to real AWS accounts
- **AWS Local**: AWS CLI commands to LocalStack endpoints for development/testing

## Development Workflow

### LocalStack Setup
LocalStack must be running for local AWS development:
```bash
# Start LocalStack with required services
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -p 4571:4571 \
  -e SERVICES=s3,ec2,lambda,dynamodb,cloudformation,iam \
  localstack/localstack

# Configure AWS CLI to use LocalStack
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

### Azure CLI Setup
Authenticate to Azure before operations:
```bash
# Login to Azure
az login

# Set subscription context
az account set --subscription <subscription-id>

# Verify context
az account show
```

### AWS CLI Setup
For production AWS operations:
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>
export AWS_DEFAULT_REGION=<region>
```

## Template Structure

Templates should follow this structure:
```
templates/
├── azure/
│   ├── compute/
│   │   ├── vm.yaml
│   │   └── aks.yaml
│   ├── storage/
│   │   └── storage-account.yaml
│   └── network/
│       └── vnet.yaml
├── aws/
│   ├── compute/
│   │   ├── ec2.yaml
│   │   └── lambda.yaml
│   ├── storage/
│   │   └── s3.yaml
│   └── network/
│       └── vpc.yaml
└── shared/
    └── schemas/
        └── validation.json
```

### Template Format
Each template defines:
- **Metadata**: Name, description, version, provider (azure/aws)
- **Parameters**: Input parameters with types and validation
- **Resources**: Resource definitions or CLI command templates
- **Outputs**: Expected outputs or return values
- **Validation**: Pre-flight checks before execution

## Claude Skills Design

Skills should be organized by operation type:
```
skills/
├── provision/     # Create new resources
├── configure/     # Update existing resources
├── query/         # Retrieve resource information
├── destroy/       # Delete resources
└── validate/      # Validate configurations
```

Each skill should:
1. Parse user request and extract parameters
2. Select appropriate template(s)
3. Validate inputs against template schemas
4. Generate CLI commands
5. Execute commands with proper error handling
6. Return structured results

## Key Considerations

### Environment Detection
Skills must detect target environment:
- Check for LocalStack endpoint configuration
- Verify Azure/AWS credentials
- Route commands to appropriate endpoint

### Error Handling
- Validate templates before execution
- Check authentication/authorization before operations
- Provide clear error messages with remediation steps
- Support dry-run mode for validation

### Security
- Never commit credentials or sensitive data
- Use environment variables or credential managers
- Support role-based access patterns
- Implement least-privilege principles in templates

### Testing
- All templates must be testable against LocalStack
- Include unit tests for template validation logic
- Integration tests for Skills execution
- Mock external API calls in tests

## Command Patterns

### Azure CLI Patterns
```bash
# Resource group operations
az group create --name <rg-name> --location <location>
az group delete --name <rg-name> --yes

# Resource operations (example: storage)
az storage account create --name <name> --resource-group <rg> --location <loc>
az storage account show --name <name> --resource-group <rg>
```

### AWS CLI Patterns (LocalStack compatible)
```bash
# S3 operations
aws s3 mb s3://<bucket-name> --endpoint-url http://localhost:4566
aws s3 ls --endpoint-url http://localhost:4566

# EC2 operations
aws ec2 describe-instances --endpoint-url http://localhost:4566
aws ec2 run-instances --image-id <ami> --instance-type t2.micro --endpoint-url http://localhost:4566
```

### Template Execution Pattern
```bash
# Generic template execution command structure
./execute-template.sh --provider <azure|aws> \
                      --template <template-path> \
                      --params <params-file> \
                      --environment <local|prod>
```

## Extensibility

### Adding New Templates
1. Create template file in appropriate provider directory
2. Define schema and validation rules
3. Add corresponding tests
4. Document parameters and usage
5. Update template registry/index

### Adding New Skills
1. Define skill intent and parameters
2. Map to required templates
3. Implement execution logic
4. Add error handling
5. Create tests and documentation

## Integration Points

### Claude Skills API
Skills expose operations through Claude Skills framework:
- Skills receive structured input from Claude
- Execute template-based operations
- Return structured results to Claude
- Support both synchronous and asynchronous operations

### CLI Tools
Primary dependencies:
- Azure CLI (`az`) - version 2.x or higher
- AWS CLI (`aws`) - version 2.x or higher
- LocalStack (`docker`) - for local AWS emulation
- jq - for JSON processing in scripts
- yq - for YAML processing in scripts

## Project Goals

1. **Template Reusability**: Create once, use across multiple projects and environments
2. **Environment Parity**: LocalStack enables testing AWS workflows locally
3. **Automation**: Claude Skills automate complex multi-step operations
4. **Consistency**: Standardized patterns for both Azure and AWS
5. **Validation**: Built-in validation prevents configuration errors
6. **Extensibility**: Easy to add new templates and skills

## Future Enhancements

- Terraform/OpenTofu integration for complex deployments
- State management for tracking provisioned resources
- Cost estimation before provisioning
- Compliance checking against organizational policies
- Multi-cloud orchestration (cross-cloud workflows)
- GitOps integration for infrastructure-as-code workflows
