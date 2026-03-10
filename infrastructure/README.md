# AgentCore Infrastructure

Terraform Infrastructure as Code for Amazon Bedrock AgentCore.

## Structure

```
infrastructure/
├── modules/              # L1 Terraform modules
│   ├── afp_terraform-aws-bedrock-agentcore-runtime/
│   ├── afp_terraform-aws-bedrock-agentcore-memory/
│   ├── afp_terraform-aws-bedrock-agentcore-gateway/
│   ├── afp_terraform-aws-bedrock-agentcore-identity/
│   ├── afp_terraform-aws-bedrock-agentcore-observability/
│   └── afp_terraform-aws-bedrock-agentcore-tools/
│
├── caller-module/        # Orchestration module
│   └── (template files)
│
└── environments/         # Environment-specific configs
    ├── dev/
    ├── staging/
    └── prod/
```

## Modules

### L1 Modules (Reusable Components)
- **Runtime**: Agent execution environment
- **Memory**: Conversation history and context
- **Gateway**: External API integration
- **Identity**: Authentication and authorization
- **Observability**: Logging, metrics, and tracing
- **Tools**: Browser, Code Interpreter, etc.

### Orchestration Module
Combines all L1 modules into a complete AgentCore deployment.

## Environments

### Dev
- Auto-deploys on push to `develop` branch
- Uses dev-specific tfvars
- Lower resource limits for cost optimization

### Staging
- Manual trigger via GitHub Actions
- Production-like configuration
- Used for pre-production testing

### Prod
- Requires approval for deployment
- Production configuration
- Higher resource limits and redundancy

## Usage

### Deploy Dev Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy via CI/CD

Push to respective branch:
- `develop` → Auto-deploys to dev
- `staging` → Manual trigger for staging
- `main` → Approval required for prod

## Configuration

Each environment has:
- `main.tf` - Module configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Environment-specific values
- `outputs.tf` - Output definitions
- `providers.tf` - Provider configuration
- `backend.tf` - S3 backend configuration

## Prerequisites

1. AWS Account with appropriate permissions
2. S3 bucket for Terraform state
3. DynamoDB table for state locking
4. ECR repository for agent container

See `../DEPLOYMENT_GUIDE.md` for detailed setup instructions.
