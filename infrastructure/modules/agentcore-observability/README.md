Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Observability Module

This Terraform module configures observability features for AWS Bedrock AgentCore resources including CloudWatch logging, X-Ray tracing, and GenAI observability dashboard.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **GenAI Observability Dashboard**: CloudWatch resource policies for X-Ray and AgentCore
- **X-Ray Tracing**: Sampling rules and trace segment destination configuration
- **Log Delivery**: CloudWatch log delivery for traces, usage logs, and application logs
- **Resource Agnostic**: Works with any AgentCore resource (runtime, memory, gateway, etc.)
- **Flexible Configuration**: Optional features with sensible defaults

## Usage

### Basic Usage - GenAI Observability Only

```hcl
module "agentcore_observability" {
  source = "./afp_terraform-aws-bedrock-agentcore-observability"

  resource_name              = "my-agent-runtime"
  enable_genai_observability = true

  tags = {
    Environment = "production"
  }
}
```

### Advanced Usage with X-Ray Tracing

```hcl
module "agentcore_observability" {
  source = "./afp_terraform-aws-bedrock-agentcore-observability"

  resource_name              = "my-agent-runtime"
  enable_genai_observability = true

  xray_sampling_rule = {
    rule_name    = "my-agent-sampling"
    service_name = "my-agent-runtime"
    priority     = 8000
    fixed_rate   = 0.1
  }

  tags = {
    Environment = "production"
  }
}
```

### Full Observability with Log Delivery

```hcl
resource "aws_cloudwatch_log_group" "usage_logs" {
  name              = "/aws/bedrock-agentcore/usage-logs"
  retention_in_days = 7
}

module "agentcore_observability" {
  source = "./afp_terraform-aws-bedrock-agentcore-observability"

  resource_name              = "my-agent-runtime"
  enable_genai_observability = true

  xray_sampling_rule = {
    rule_name    = "my-agent-sampling"
    service_name = "my-agent-runtime"
    priority     = 8000
    fixed_rate   = 0.1
  }

  log_deliveries = {
    runtime-traces = {
      resource_arn             = aws_bedrockagentcore_runtime.agent.arn
      log_type                 = "TRACES"
      destination_type         = "XRAY"
      destination_resource_arn = null
    }
    runtime-usage = {
      resource_arn             = aws_bedrockagentcore_runtime.agent.arn
      log_type                 = "USAGE_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.usage_logs.arn
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_cloudwatch_log_resource_policy.genai_observability | resource |
| aws_xray_sampling_rule.this | resource |
| aws_bedrockagentcore_log_delivery.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_name | Name of the AgentCore resource | `string` | n/a | yes |
| enable_genai_observability | Enable GenAI Observability Dashboard | `bool` | `true` | no |
| xray_sampling_rule | X-Ray sampling rule configuration | `object` | `null` | no |
| log_deliveries | Map of log delivery configurations | `map(object)` | `{}` | no |
| additional_log_policy_statements | Additional IAM policy statements for log policy | `list(any)` | `[]` | no |
| name_prefix | Prefix for resource names | `string` | `""` | no |
| core_tags | Default tags applied to all AWS resources | `map(string)` | `{}` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| genai_observability_policy_name | CloudWatch Logs resource policy name |
| xray_sampling_rule_name | X-Ray sampling rule name |
| xray_sampling_rule_arn | X-Ray sampling rule ARN |
| log_delivery_sources | Map of log delivery source names |
| log_delivery_destinations | Map of log delivery destination ARNs |

## Security Considerations

- CloudWatch Logs resource policies follow least privilege principles
- X-Ray tracing data is encrypted in transit and at rest
- Log delivery supports encryption via KMS

## License

This module is licensed under the Apache 2.0 License.
