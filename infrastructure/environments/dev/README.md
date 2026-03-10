# Bedrock AgentCore Caller Module

This module creates a complete Bedrock AgentCore infrastructure by orchestrating all L1 modules:

- **AgentCore Tools** (Browser & Code Interpreter)
- **AgentCore Identity** (API Key, OAuth2, Workload Identity providers)
- **AgentCore Gateway** (MCP Gateway)
- **AgentCore Memory** (Memory & Memory Strategy)
- **AgentCore Runtime** (Runtime & Runtime Endpoint)
- **AgentCore Observability** (Monitoring, Alarms, X-Ray Tracing)

## Architecture

The module creates a complete AgentCore environment with:

1. **IAM Roles & Policies** for each component
2. **KMS Key** for encryption (optional)
3. **CloudWatch Logs** for runtime logging
4. **All L1 AgentCore modules** with proper integration
5. **Comprehensive monitoring** and alerting

## Usage

```hcl
module "bedrock_agentcore" {
  source = "./bedrock-agentcore-caller"

  project_name = "my-agentcore"
  environment  = "dev"
  aws_region   = "us-east-1"

  # Tools Configuration
  enable_browser          = true
  enable_code_interpreter = true

  # Identity Configuration
  enable_api_key_provider  = true
  enable_oauth2_provider   = false
  enable_workload_identity = false
  api_key                  = var.api_key  # Pass via variable, never hardcode

  # Gateway Configuration
  enable_gateway = true

  # Memory Configuration
  enable_memory          = true
  enable_memory_strategy = false

  # Runtime Configuration
  enable_runtime          = true
  enable_runtime_endpoint = true
  container_uri          = "your-ecr-uri"

  # Observability Configuration
  enable_genai_observability = true
  enable_runtime_alarms     = true
  enable_memory_alarms      = false
  enable_gateway_alarms     = false
  enable_identity_alarms    = false
  enable_xray_tracing       = false

  # Security
  create_kms_key = true

  tags = {
    Environment = "development"
    Project     = "AgentCore"
  }
}
```

## Observability Features

### GenAI Observability Dashboard
- Automatically configures CloudWatch Logs resource policies
- Enables GenAI Observability Dashboard in CloudWatch
- Provides comprehensive monitoring for Bedrock AgentCore components

### CloudWatch Alarms
The module creates alarms for:

#### Runtime Alarms
- **Total Errors**: Monitors overall error count
- **System Errors**: Monitors system-level errors
- **High Latency**: Monitors response time performance
- **Throttles**: Monitors throttling events

#### Memory Alarms (Optional)
- **Errors**: Monitors memory component errors
- **Throttles**: Monitors memory throttling

#### Gateway Alarms (Optional)
- **Errors**: Monitors gateway errors
- **Throttles**: Monitors gateway throttling

#### Identity Alarms (Optional)
- **Errors**: Monitors identity provider errors
- **Throttles**: Monitors identity throttling

### X-Ray Tracing (Optional)
- Configures X-Ray sampling rules
- Sets up trace segment destinations
- Provides distributed tracing capabilities

## Variables

### Core Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_name` | Name of the project | `string` | Required |
| `environment` | Environment name | `string` | `"dev"` |
| `aws_region` | AWS region | `string` | `"us-east-1"` |

### Component Enablement
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_browser` | Enable browser functionality | `bool` | `true` |
| `enable_code_interpreter` | Enable code interpreter | `bool` | `true` |
| `enable_api_key_provider` | Enable API key provider | `bool` | `true` |
| `enable_oauth2_provider` | Enable OAuth2 provider | `bool` | `false` |
| `enable_workload_identity` | Enable workload identity | `bool` | `false` |
| `enable_gateway` | Enable gateway | `bool` | `true` |
| `enable_memory` | Enable memory | `bool` | `true` |
| `enable_memory_strategy` | Enable memory strategy | `bool` | `false` |
| `enable_runtime` | Enable runtime | `bool` | `true` |
| `enable_runtime_endpoint` | Enable runtime endpoint | `bool` | `false` |

### Observability Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_genai_observability` | Enable GenAI Observability Dashboard | `bool` | `true` |
| `enable_runtime_alarms` | Enable runtime CloudWatch alarms | `bool` | `true` |
| `enable_memory_alarms` | Enable memory CloudWatch alarms | `bool` | `false` |
| `enable_gateway_alarms` | Enable gateway CloudWatch alarms | `bool` | `false` |
| `enable_identity_alarms` | Enable identity CloudWatch alarms | `bool` | `false` |
| `enable_xray_tracing` | Enable X-Ray tracing | `bool` | `false` |

### Alarm Thresholds
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `error_rate_threshold` | Error count threshold | `number` | `5` |
| `error_rate_period` | Error rate period (seconds) | `number` | `300` |
| `error_rate_evaluation_periods` | Error rate evaluation periods | `number` | `2` |
| `latency_threshold` | Latency threshold (ms) | `number` | `5000` |
| `latency_period` | Latency period (seconds) | `number` | `300` |
| `latency_evaluation_periods` | Latency evaluation periods | `number` | `2` |
| `alarm_actions` | SNS topics for alarm notifications | `list(string)` | `[]` |
| `ok_actions` | SNS topics for recovery notifications | `list(string)` | `[]` |

### X-Ray Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `xray_sampling_priority` | X-Ray sampling rule priority | `number` | `9000` |
| `xray_reservoir_size` | X-Ray reservoir size | `number` | `1` |
| `xray_fixed_rate` | X-Ray fixed sampling rate | `number` | `0.1` |

## Outputs

### Core Outputs
- `kms_key_id`, `kms_key_arn` - KMS key information
- `*_role_arn` - IAM role ARNs for each component

### Component Outputs
- `browser_*`, `code_interpreter_*` - Tools outputs
- `identity_*` - Identity provider outputs
- `gateway_*` - Gateway outputs
- `memory_*` - Memory outputs
- `runtime_*` - Runtime outputs

### Observability Outputs
- `observability` - Complete observability module outputs
- `runtime_alarms` - Runtime alarm details
- `memory_alarms` - Memory alarm details
- `gateway_alarms` - Gateway alarm details
- `identity_alarms` - Identity alarm details
- `xray_sampling_rule` - X-Ray sampling rule details
- `all_alarm_arns` - List of all alarm ARNs
- `monitoring_dashboard_url` - CloudWatch GenAI Observability dashboard URL

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0
3. Access to Bedrock AgentCore service
4. ECR repository with AgentCore runtime container (if using runtime)
5. SSM parameter `/aft/account-request/custom-fields/core_tags` with core tags JSON

## Deployment

1. Update `terraform.tfvars` with your configuration
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Plan the deployment:
   ```bash
   terraform plan
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Monitoring

After deployment, you can:

1. **View GenAI Observability Dashboard**: Use the `monitoring_dashboard_url` output
2. **Monitor Alarms**: Check CloudWatch alarms in the AWS Console
3. **View Logs**: Check CloudWatch Logs for runtime logs
4. **X-Ray Traces**: View distributed traces in X-Ray console (if enabled)

## Security Considerations

- IAM roles use permissions boundaries
- KMS encryption available for sensitive data
- CloudWatch Logs retention configured
- Least privilege access patterns

## Troubleshooting

### Common Issues

1. **Permissions Boundary**: Ensure the mandatory permissions boundary policy exists
2. **ECR Access**: Verify the container URI is accessible
3. **SSM Parameter**: Ensure core_tags SSM parameter exists
4. **Service Availability**: Verify Bedrock AgentCore is available in your region

### Logs

- Runtime logs: `/aws/bedrock-agentcore/runtimes/{runtime-id}-DEFAULT`
- Check CloudWatch Logs for detailed error messages