# AgentCore DevOps Solution

Complete end-to-end solution for deploying agentic AI applications using Amazon Bedrock AgentCore with automated CI/CD.

## Repository Structure

```
agentcore-solution/
├── agent-app/                      # Agentic AI Application
│   ├── src/
│   │   ├── agent.py               # Main agent logic
│   │   ├── tools.py               # Custom tools
│   │   └── config.py              # Configuration
│   ├── tests/
│   │   ├── test_agent.py          # Unit tests
│   │   └── test_integration.py    # Integration tests
│   ├── Dockerfile                 # Container definition
│   ├── requirements.txt           # Python dependencies
│   └── README.md                  # App documentation
│
├── infrastructure/                 # Terraform Infrastructure
│   ├── modules/                   # L1 Terraform modules
│   │   ├── agentcore-runtime/
│   │   ├── agentcore-memory/
│   │   ├── agentcore-gateway/
│   │   ├── agentcore-identity/
│   │   ├── agentcore-tools/
│   │   └── agentcore-observability/
│   ├── environments/              # Environment configs
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── terraform.tfvars
│   │   ├── staging/
│   │   └── prod/
│   └── caller-module/             # Orchestration module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── .github/
│   └── workflows/
│       ├── 01-build-agent.yml     # Build & push container
│       ├── 02-deploy-infra.yml    # Deploy infrastructure
│       ├── 03-update-runtime.yml  # Update with new image
│       └── ci.yml                 # Continuous integration
│
├── docs/
│   ├── architecture.md
│   └── deployment-guide.md
│
├── scripts/
│   ├── build-and-push.sh
│   └── deploy.sh
│
└── README.md
```

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Code Push to GitHub                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. GitHub Actions: Build Agent Container                   │
│     - Run tests                                             │
│     - Build Docker image                                    │
│     - Push to ECR with version tag                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. GitHub Actions: Deploy Infrastructure                   │
│     - Terraform init/plan/apply                             │
│     - Create AgentCore components                           │
│     - Deploy runtime with new container                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. GitHub Actions: Update Runtime Endpoint                 │
│     - Create new runtime version                            │
│     - Update endpoint to new version                        │
│     - Run smoke tests                                       │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Clone Repository
```bash
git clone <your-repo>
cd agentcore-solution
```

### 2. Configure AWS Credentials
```bash
# Set up GitHub OIDC for AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

### 3. Deploy Development Environment
```bash
cd infrastructure/environments/dev
terraform init
terraform apply
```

### 4. Build and Deploy Agent
```bash
cd ../../../agent-app
docker build -t agent:dev .
# Push to ECR (automated via GitHub Actions)
```

## Environment Variables

### GitHub Secrets Required
- `AWS_ACCOUNT_ID` - Your AWS account ID
- `AWS_REGION` - Deployment region (default: us-east-1)
- `ECR_REPOSITORY` - ECR repository name
- `TF_STATE_BUCKET` - S3 bucket for Terraform state

### Agent App Environment Variables
- `RUNTIME_ID` - AgentCore runtime ID
- `MEMORY_ID` - AgentCore memory ID
- `GATEWAY_URL` - AgentCore gateway endpoint
- `API_KEY` - Authentication key

## Key Features

✅ **Automated CI/CD Pipeline**
- Build agent container on code push
- Deploy infrastructure with Terraform
- Update runtime with new versions
- Automated testing and validation

✅ **Modular Infrastructure**
- 6 reusable Terraform modules
- Environment-specific configurations
- Easy to extend and customize

✅ **Production-Ready Agent**
- Sample agentic AI application
- Integration with AgentCore services
- Memory, tools, and gateway support

✅ **Multi-Environment Support**
- Dev, Staging, Production
- Approval gates for production
- Environment-specific configurations

## Deployment Commands

### Manual Deployment
```bash
# Build agent
./scripts/build-and-push.sh dev v1.0.0

# Deploy infrastructure
./scripts/deploy.sh dev

# Update runtime
cd infrastructure/environments/dev
terraform apply -var="container_version=v1.0.0"
```

### Automated Deployment (GitHub Actions)
```bash
# Push to develop branch → Auto-deploy to dev
git push origin develop

# Create release tag → Deploy to production
git tag v1.0.0
git push origin v1.0.0
```

## Testing

### Unit Tests
```bash
cd agent-app
pytest tests/test_agent.py
```

### Integration Tests
```bash
pytest tests/test_integration.py --runtime-id <runtime-id>
```

### Smoke Tests
```bash
python tests/smoke_test.py --endpoint <endpoint-arn>
```

## Monitoring

### CloudWatch Logs
```bash
aws logs tail /aws/bedrock-agentcore/agentcore-dev-runtime --follow
```

### X-Ray Traces
View in AWS Console → X-Ray → Traces

### Metrics
View in AWS Console → CloudWatch → Dashboards

## Troubleshooting

See [docs/deployment-guide.md](docs/deployment-guide.md) for common issues and solutions.

## Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit PR
5. Auto-deploy to dev on merge

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

