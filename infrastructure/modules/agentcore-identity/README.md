Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Identity Module

This Terraform module creates and manages AWS Bedrock AgentCore Identity resources for authentication, authorization, and credential management.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **API Key Credentials**: Secure API key credential provider management
- **OAuth2 Integration**: Support for OAuth2 credential providers including GitHub and custom providers
- **Workload Identity**: Manage workload identities for AgentCore resources
- **Flexible Authentication**: Multiple authentication provider types
- **Security**: Secure credential storage with write-only options

## Usage

### Basic Usage with API Key Provider

```hcl
module "agentcore_identity" {
  source = "./afp_terraform-aws-bedrock-agentcore-identity"

  create_api_key_provider = true
  api_key_provider_name   = var.my-api-key-provider   #Pass via variable, never hardcode
  api_key_wo_version      = 1

  tags = {
    Environment = "production"
    Service     = "agentcore"
  }
}
```

### Advanced Usage with OAuth2 Provider

```hcl
module "agentcore_identity" {
  source = "./afp_terraform-aws-bedrock-agentcore-identity"

  create_oauth2_provider  = true
  oauth2_provider_name    = "my-oauth2-provider"
  oauth2_provider_vendor  = "CustomOauth2"

  oauth2_provider_config = {
    custom_oauth2_provider_config = {
      client_id_wo                  = var.oauth2_client_id      # Pass via variable
      client_secret_wo              = var.oauth2_client_secret   # Pass via variable
      client_credentials_wo_version = 1
      oauth_discovery = {
        discovery_url = "https://auth.example.com/.well-known/openid-configuration"
      }
    }
  }

  tags = {
    Environment = "production"
    Service     = "agentcore"
  }
}
```

### Workload Identity Configuration

```hcl
module "agentcore_identity" {
  source = "./afp_terraform-aws-bedrock-agentcore-identity"

  create_workload_identity = true
  workload_identity_name   = "my-workload-identity"
  
  allowed_resource_oauth2_return_urls = [
    "https://example.com/callback",
    "https://app.example.com/oauth/callback"
  ]

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
| aws_bedrockagentcore_api_key_credential_provider.this | resource |
| aws_bedrockagentcore_oauth2_credential_provider.this | resource |
| aws_bedrockagentcore_workload_identity.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_api_key_provider | Whether to create API key credential provider | `bool` | `true` | no |
| api_key_provider_name | Name of the API key credential provider | `string` | `null` | no |
| api_key | API key for the credential provider | `string` | `null` | no |
| api_key_wo | Write-only API key for the credential provider | `string` | `null` | no |
| api_key_wo_version | Version number for write-only API key updates | `number` | `null` | no |
| create_oauth2_provider | Whether to create OAuth2 credential provider | `bool` | `false` | no |
| oauth2_provider_name | Name of the OAuth2 credential provider | `string` | `null` | no |
| oauth2_provider_vendor | Vendor of the OAuth2 credential provider | `string` | `"CustomOauth2"` | no |
| oauth2_provider_config | OAuth2 provider configuration | `object` | `null` | no |
| create_workload_identity | Whether to create workload identity | `bool` | `false` | no |
| workload_identity_name | Name of the workload identity | `string` | `null` | no |
| allowed_resource_oauth2_return_urls | Allowed OAuth2 return URLs for resources | `list(string)` | `[]` | no |
| create_token_vault_cmk | Whether to create token vault CMK | `bool` | `false` | no |
| token_vault_id | Token vault ID | `string` | `"default"` | no |
| kms_configuration | KMS configuration for the token vault | `object` | `null` | no |
| core_tags | Default tags applied to all AWS resources | `map(string)` | `{}` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_key_provider_arn | ARN of the API key credential provider |
| api_key_secret_arn | ARN of the API key secret |
| oauth2_provider_arn | ARN of the OAuth2 credential provider |
| oauth2_provider_name | Name of the OAuth2 credential provider |
| workload_identity_arn | ARN of the workload identity |
| workload_identity_name | Name of the workload identity |

## Security Considerations

- Use write-only (wo) parameters for sensitive credentials in production
- API keys and OAuth2 credentials are stored securely
- IAM roles follow least privilege principles
- Support for credential rotation via version management

## License

This module is licensed under the Apache 2.0 License.
