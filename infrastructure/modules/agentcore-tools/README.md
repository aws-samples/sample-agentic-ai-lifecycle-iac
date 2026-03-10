Copyright © Amazon.com and Affiliates: This deliverable is considered Developed Content as defined in the AWS Service Terms and the SOW between the parties dated [date].

# Amazon Bedrock AgentCore Tools Module

This Terraform module creates AWS Bedrock AgentCore tool resources including browser automation and code interpreter capabilities.

## Authors

Module is maintained by AWS Federated Team (AWS-Federated-Devops) (ichauthaiwale@statestreet.com, AWS)

## Features

- **Browser Automation**: Web browser automation for agent workflows
- **Code Interpreter**: Code execution and interpretation capabilities
- **IAM Integration**: Proper execution roles and policies
- **Tagging Support**: Consistent resource tagging

## Usage

### Basic Usage

```hcl
module "agentcore_tools" {
  source = "./afp_terraform-aws-bedrock-agentcore"

  # Browser Configuration
  create_browser             = true
  browser_name              = "my-browser"
  browser_description       = "Browser for web automation"
  browser_execution_role_arn = aws_iam_role.browser_role.arn

  # Code Interpreter Configuration
  create_code_interpreter                = true
  code_interpreter_name                 = "my-code-interpreter"
  code_interpreter_description          = "Code interpreter for agent"
  code_interpreter_execution_role_arn   = aws_iam_role.code_role.arn

  tags = {
    Environment = "production"
    Team        = "ai-platform"
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
| aws_bedrockagentcore_browser.this | resource |
| aws_bedrockagentcore_code_interpreter.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_browser | Whether to create browser resource | `bool` | `false` | no |
| browser_name | Name of the browser | `string` | `null` | no |
| browser_description | Description of the browser | `string` | `null` | no |
| browser_execution_role_arn | IAM role ARN for browser | `string` | `null` | no |
| browser_network_configuration | Network configuration for the browser | `object` | `null` | no |
| browser_recording | Recording configuration for browser sessions | `object` | `null` | no |
| browser_timeouts | Timeout configuration for browser operations | `object` | `null` | no |
| create_code_interpreter | Whether to create code interpreter | `bool` | `false` | no |
| code_interpreter_name | Name of the code interpreter | `string` | `null` | no |
| code_interpreter_description | Description of code interpreter | `string` | `null` | no |
| code_interpreter_execution_role_arn | IAM role ARN for code interpreter | `string` | `null` | no |
| code_interpreter_network_configuration | Network configuration for the code interpreter | `object` | `null` | no |
| code_interpreter_timeouts | Timeout configuration for code interpreter operations | `object` | `null` | no |
| core_tags | Default tags applied to all AWS resources | `map(string)` | `{}` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| browser_id | ID of the browser resource |
| browser_arn | ARN of the browser resource |
| code_interpreter_id | ID of the code interpreter resource |
| code_interpreter_arn | ARN of the code interpreter resource |

## Security Considerations

- IAM roles follow least privilege principles
- Proper execution roles required for browser and code interpreter resources

## License

This module is licensed under the Apache 2.0 License.
