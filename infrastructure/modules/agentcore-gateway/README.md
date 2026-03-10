Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Gateway Module

This Terraform module creates and manages AWS Bedrock AgentCore Gateway resources for API management, routing, and access control.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **API Gateway Management**: Create and configure AgentCore gateways
- **Authentication**: Support for IAM and custom authorization methods
- **Route Management**: Define routes with path patterns and HTTP methods
- **Target Integration**: Route requests to AgentCore runtimes, Lambda functions, or HTTP endpoints
- **Security**: KMS encryption and IAM role-based access control

## Usage

### Basic Usage

```hcl
module "agentcore_gateway" {
  source = "./afp_terraform-aws-bedrock-agentcore-gateway"

  gateway_name        = "my-agentcore-gateway"
  gateway_description = "API gateway for AgentCore services"
  gateway_role_arn    = "arn:aws:iam::123456789012:role/GatewayRole"

  create_gateway_target = true
  gateway_target_name   = "api-target"
  
  target_configuration = {
    mcp = {
      lambda = {
        lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
        tool_schema = {
          inline_payload = {
            name        = "my-tool"
            description = "My tool description"
            input_schema = {
              type = "object"
            }
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Service     = "agentcore"
  }
}
```

### Advanced Usage with Custom Authorization

```hcl
module "agentcore_gateway" {
  source = "./afp_terraform-aws-bedrock-agentcore-gateway"

  gateway_name        = "my-agentcore-gateway"
  gateway_description = "API gateway for AgentCore services"
  gateway_role_arn    = "arn:aws:iam::123456789012:role/GatewayRole"
  
  authorizer_type = "CUSTOM"
  authorizer_configuration = {
    custom_jwt_authorizer = {
      discovery_url    = "https://auth.example.com/.well-known/jwks.json"
      allowed_audience = ["api://gateway"]
      allowed_clients  = ["client-id-1"]
    }
  }

  kms_key_arn = ""

  create_gateway_target = true
  gateway_target_name   = "api-target"
  protocol_type         = "MCP"
  
  target_configuration = {
    mcp = {
      lambda = {
        lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
        tool_schema = {
          inline_payload = {
            name        = "my-tool"
            description = "My tool description"
            input_schema = {
              type = "object"
            }
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Service     = "agentcore"
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
| aws_bedrockagentcore_gateway.this | resource |
| aws_bedrockagentcore_gateway_target.this | resource |
| aws_iam_role.gateway_role | resource |
| aws_iam_role_policy.gateway_policy | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_gateway | Whether to create the gateway | `bool` | `true` | no |
| gateway_name | Name of the AgentCore gateway | `string` | `null` | no |
| gateway_description | Description of the AgentCore gateway | `string` | `null` | no |
| gateway_role_arn | ARN of the IAM role for the gateway | `string` | `null` | no |
| authorizer_type | The authorizer type for the gateway | `string` | `"AWS_IAM"` | no |
| authorizer_configuration | Authorizer configuration for the gateway | `object` | `null` | no |
| protocol_type | The protocol type for the gateway target | `string` | `"MCP"` | no |
| protocol_configuration | Protocol configuration for the gateway | `object` | `null` | no |
| kms_key_arn | KMS key ARN for gateway encryption | `string` | `null` | no |
| create_gateway_target | Whether to create gateway target | `bool` | `false` | no |
| gateway_target_name | Name of the gateway target | `string` | `null` | no |
| gateway_target_description | Description of the gateway target | `string` | `null` | no |
| credential_provider_configuration | Configuration for authenticating requests to the target | `object` | `null` | no |
| target_configuration | Configuration for the target endpoint | `object` | `null` | no |
| core_tags | Default tags applied to all AWS resources | `map(string)` | `{}` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | ID of the AgentCore gateway |
| gateway_arn | ARN of the AgentCore gateway |
| gateway_endpoint | Endpoint URL of the AgentCore gateway |
| gateway_target_id | ID of the AgentCore gateway target |
| gateway_role_arn | ARN of the IAM role created for the gateway |

## Security Considerations

- IAM roles follow least privilege principles
- KMS encryption available for gateway data
- Support for custom authorization mechanisms

## License

This module is licensed under the Apache 2.0 License.
