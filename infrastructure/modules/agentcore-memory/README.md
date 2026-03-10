Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Memory Module

This Terraform module manages AWS Bedrock AgentCore memory resources including memory configuration and memory strategies.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **AgentCore Memory**: Creation and configuration of agent memory resources
- **Memory Strategy**: Custom memory handling strategies including semantic, summary, and user preference
- **Encryption**: KMS encryption support for memory data
- **IAM Integration**: Role-based access control for memory operations
- **Configurable Expiry**: Flexible memory event expiration settings

## Usage

### Basic Usage

```hcl
module "agentcore_memory" {
  source = "./afp_terraform-aws-bedrock-agentcore-memory"
  
  memory_name                 = "my-agent-memory"
  memory_description          = "Memory for my AI agent"
  memory_event_expiry_duration = 30
  memory_encryption_key_arn   = ""
  memory_execution_role_arn   = "arn:aws:iam::123456789012:role/AgentMemoryRole"
  
  tags = {
    Environment = "production"
    Project     = "ai-agent"
  }
}
```

### Advanced Usage with Memory Strategy

```hcl
module "agentcore_memory" {
  source = "./afp_terraform-aws-bedrock-agentcore-memory"
  
  memory_name                 = "my-agent-memory"
  memory_description          = "Memory for my AI agent"
  memory_event_expiry_duration = 30
  memory_encryption_key_arn   = ""
  memory_execution_role_arn   = "arn:aws:iam::123456789012:role/AgentMemoryRole"
  
  create_memory_strategy      = true
  memory_strategy_name        = "custom-strategy"
  memory_strategy_type        = "CUSTOM"
  memory_strategy_namespaces  = ["default"]
  
  memory_strategy_configuration = {
    type = "SEMANTIC_OVERRIDE"
    consolidation = {
      append_to_prompt = "Consolidate the following memories:"
      model_id         = "anthropic.claude-3-sonnet-20240229-v1:0"
    }
    extraction = {
      append_to_prompt = "Extract key information from:"
      model_id         = "anthropic.claude-3-sonnet-20240229-v1:0"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "ai-agent"
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
| aws_bedrockagentcore_memory.this | resource |
| aws_bedrockagentcore_memory_strategy.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_memory | Whether to create the AgentCore memory | `bool` | `true` | no |
| memory_name | Name of the AgentCore memory | `string` | `null` | no |
| memory_description | Description of the AgentCore memory | `string` | `null` | no |
| memory_event_expiry_duration | Event expiry duration for the memory (in days) | `number` | `30` | no |
| memory_encryption_key_arn | ARN of the KMS key used to encrypt the memory | `string` | `null` | no |
| memory_execution_role_arn | ARN of the IAM role that the memory service assumes | `string` | `null` | no |
| create_memory_strategy | Whether to create the memory strategy | `bool` | `false` | no |
| memory_strategy_name | Name of the memory strategy | `string` | `null` | no |
| memory_strategy_description | Description of the memory strategy | `string` | `null` | no |
| memory_strategy_type | Type of the memory strategy | `string` | `"SEMANTIC"` | no |
| memory_strategy_namespaces | Namespaces for the memory strategy | `list(string)` | n/a | yes |
| memory_strategy_configuration | Custom configuration for CUSTOM type memory strategies | `object` | `null` | no |
| core_tags | Default tags applied to all AWS resources | `map(string)` | `{}` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| memory_arn | ARN of the AgentCore memory |
| memory_id | ID of the AgentCore memory |
| memory_name | Name of the AgentCore memory |
| memory_strategy_id | ID of the AgentCore memory strategy |
| memory_strategy_name | Name of the AgentCore memory strategy |
| memory_strategy_type | Type of the AgentCore memory strategy |

## Security Considerations

- KMS encryption recommended for memory data at rest
- IAM roles follow least privilege principles
- Configurable memory expiration for data retention compliance

## License

This module is licensed under the Apache 2.0 License.
