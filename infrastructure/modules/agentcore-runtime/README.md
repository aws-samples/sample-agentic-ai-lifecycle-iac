Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Runtime Module

This Terraform module manages AWS Bedrock AgentCore runtime resources including the agent runtime and runtime endpoints.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **AgentCore Runtime**: Complete runtime creation and configuration
- **Runtime Endpoint**: Endpoint management with versioning support
- **Network Flexibility**: Support for VPC and public network deployments
- **Security Integration**: JWT authorization and IAM role configuration
- **Lifecycle Management**: Configurable session timeouts and resource lifecycle
- **Protocol Support**: HTTP, MCP, and A2A protocol configurations
- **Container Deployment**: ECR-based container runtime deployment

## Usage

### Basic Usage

```hcl
module "agentcore_runtime" {
  source = "./afp_terraform-aws-bedrock-agentcore-runtime"
  
  agent_runtime_name     = "my-agent-runtime"
  agent_runtime_role_arn = "arn:aws:iam::123456789012:role/AgentRuntimeRole"
  container_uri          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:latest"
  
  agent_runtime_endpoint_name = "my-agent-endpoint"
  
  tags = {
    Environment = "production"
    Project     = "ai-agent"
  }
}
```

### Advanced Usage with VPC and JWT Authorization

```hcl
module "agentcore_runtime" {
  source = "./afp_terraform-aws-bedrock-agentcore-runtime"
  
  agent_runtime_name         = "my-agent-runtime"
  agent_runtime_role_arn     = "arn:aws:iam::123456789012:role/AgentRuntimeRole"
  container_uri              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-agent:latest"
  agent_runtime_description  = "Production AI agent runtime"
  
  agent_runtime_environment_variables = {
    LOG_LEVEL = "INFO"
    DEBUG     = "false"
  }
  
  network_configuration = {
    network_mode = "VPC"
    vpc_configuration = {
      subnet_ids         = ["subnet-12345", "subnet-67890"]
      security_group_ids = ["sg-12345"]
    }
  }
  
  authorizer_configuration = {
    custom_jwt_authorizer = {
      discovery_url    = "https://auth.example.com/.well-known/jwks.json"
      allowed_audience = ["api://agent-runtime"]
      allowed_clients  = ["client-id-1", "client-id-2"]
    }
  }
  
  lifecycle_configuration = {
    idle_runtime_session_timeout = 300
    max_lifetime                 = 3600
  }
  
  protocol_configuration = "HTTP"
  
  create_agent_runtime_endpoint = true
  agent_runtime_endpoint_name   = "my-agent-endpoint"
  agent_runtime_endpoint_description = "Production endpoint for my AI agent"
  
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
| aws_bedrockagentcore_agent_runtime.this | resource |
| aws_bedrockagentcore_agent_runtime_endpoint.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_runtime_name | Name of the AgentCore runtime | `string` | n/a | yes |
| agent_runtime_role_arn | ARN of IAM role for AgentCore runtime | `string` | n/a | yes |
| agent_runtime_endpoint_name | Name of the AgentCore runtime endpoint | `string` | n/a | yes |
| container_uri | ECR container URI for the AgentCore runtime | `string` | `null` | no |
| code_configuration | S3 code configuration (alternative to container_uri) | `object` | `null` | no |
| create_agent_runtime | Whether to create the AgentCore runtime | `bool` | `true` | no |
| create_agent_runtime_endpoint | Whether to create the runtime endpoint | `bool` | `true` | no |
| agent_runtime_description | Description of the AgentCore runtime | `string` | `null` | no |
| agent_runtime_endpoint_description | Description of the runtime endpoint | `string` | `null` | no |
| agent_runtime_environment_variables | Environment variables for the runtime | `map(string)` | `{}` | no |
| network_configuration | Network configuration for the runtime | `object` | `null` | no |
| authorizer_configuration | JWT authorization configuration | `object` | `null` | no |
| lifecycle_configuration | Lifecycle management configuration | `object` | `null` | no |
| protocol_configuration | Protocol configuration (HTTP/MCP/A2A) | `string` | `null` | no |
| request_header_configuration | Request header allowlist configuration | `object` | `null` | no |
| agent_runtime_timeouts | Timeout configuration for runtime operations | `object` | `null` | no |
| agent_runtime_endpoint_timeouts | Timeout configuration for endpoint operations | `object` | `null` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| agent_runtime_arn | ARN of the AgentCore runtime |
| agent_runtime_id | Unique identifier of the AgentCore runtime |
| agent_runtime_name | Name of the AgentCore runtime |
| agent_runtime_version | Version of the AgentCore runtime |
| agent_runtime_endpoint_arn | ARN of the AgentCore runtime endpoint |
| agent_runtime_endpoint_name | Name of the AgentCore runtime endpoint |
| runtime_created | Boolean indicating if the runtime was created |
| endpoint_created | Boolean indicating if the endpoint was created |

## Security Considerations

- IAM roles follow least privilege principles
- Support for VPC deployment for network isolation
- JWT authorization for secure API access
- Container images should be scanned for vulnerabilities

## License

This module is licensed under the Apache 2.0 License.
