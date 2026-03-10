# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AGENTCORE GATEWAY VARIABLES
# =============================================================================
# Variables for configuring the AWS Bedrock AgentCore gateway module.
# This module supports API management, routing, authentication, rate limiting,
# and integration with AgentCore runtimes.
# =============================================================================

# =============================================================================
# GATEWAY CONFIGURATION
# =============================================================================

variable "create_gateway" {
  description = "Whether to create the AgentCore gateway resource"
  type        = bool
  default     = true
}

variable "gateway_name" {
  description = "Name of the AgentCore gateway (must match regex: ^[a-zA-Z][a-zA-Z0-9_-]{0,62}$)"
  type        = string
  default     = null
}

variable "gateway_description" {
  description = "Description of the AgentCore gateway"
  type        = string
  default     = null
}

variable "authorizer_type" {
  description = "The authorizer type for the gateway"
  type        = string
  default     = "AWS_IAM"
}

variable "protocol_type" {
  description = "The protocol type for the gateway target"
  type        = string
  default     = "MCP"
}

variable "gateway_role_arn" {
  description = "ARN of the IAM role for the gateway"
  type        = string
  default     = null
}

variable "exception_level" {
  description = "Exception level for the gateway"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for gateway encryption"
  type        = string
  default     = null
}

variable "authorizer_configuration" {
  description = "Authorizer configuration for the gateway"
  type = object({
    custom_jwt_authorizer = optional(object({
      discovery_url    = string
      allowed_audience = optional(set(string))
      allowed_clients  = optional(set(string))
    }))
  })
  default = null
}

variable "protocol_configuration" {
  description = "Protocol configuration for the gateway"
  type = object({
    mcp = optional(object({
      instructions       = optional(string)
      search_type        = optional(string)
      supported_versions = optional(set(string))
    }))
  })
  default = null
}

variable "interceptor_configuration" {
  description = "List of interceptor configurations for the gateway"
  type = list(object({
    interception_points = set(string)
    interceptor = object({
      lambda = object({
        arn = string
      })
    })
    input_configuration = optional(object({
      pass_request_headers = bool
    }))
  }))
  default = null
}


# =============================================================================
# AUTHENTICATION CONFIGURATION
# =============================================================================


# =============================================================================
# RATE LIMITING CONFIGURATION
# =============================================================================


# =============================================================================
# CORS CONFIGURATION
# =============================================================================


# =============================================================================
# GATEWAY TARGET CONFIGURATION
# =============================================================================

variable "create_gateway_target" {
  description = "Whether to create the AgentCore gateway target"
  type        = bool
  default     = false
}

variable "gateway_identifier" {
  description = "Gateway identifier for the target (required if create_gateway is false)"
  type        = string
  default     = null
}

variable "gateway_target_name" {
  description = "Name of the AgentCore gateway target"
  type        = string
  default     = null
}

variable "gateway_target_description" {
  description = "Description of the AgentCore gateway target"
  type        = string
  default     = null
}

variable "credential_provider_configuration" {
  description = "Configuration for authenticating requests to the target"
  type = object({
    gateway_iam_role = optional(object({}))
    api_key = optional(object({
      provider_arn              = string
      credential_location       = optional(string)
      credential_parameter_name = optional(string)
      credential_prefix         = optional(string)
    }))
    oauth = optional(object({
      provider_arn      = string
      scopes            = optional(set(string))
      custom_parameters = optional(map(string))
    }))
  })
  default = null
}

variable "target_configuration" {
  description = "Configuration for the target endpoint"
  type = object({
    mcp = optional(object({
      lambda = optional(object({
        lambda_arn = string
        tool_schema = object({
          inline_payload = optional(object({
            name        = string
            description = string
            input_schema = object({
              type        = string
              description = optional(string)
              property = optional(list(object({
                name        = string
                type        = string
                description = optional(string)
                required    = optional(bool)
                items = optional(object({
                  type        = string
                  description = optional(string)
                }))
                property = optional(list(object({
                  name        = string
                  type        = string
                  description = optional(string)
                  required    = optional(bool)
                })))
              })))
              items = optional(object({
                type        = string
                description = optional(string)
              }))
            })
            output_schema = optional(object({
              type        = string
              description = optional(string)
              property = optional(list(object({
                name        = string
                type        = string
                description = optional(string)
                required    = optional(bool)
              })))
            }))
          }))
          s3 = optional(object({
            uri                     = optional(string)
            bucket_owner_account_id = optional(string)
          }))
        })
      }))
      mcp_server = optional(object({
        endpoint = string
      }))
      open_api_schema = optional(object({
        inline_payload = optional(object({
          payload = string
        }))
        s3 = optional(object({
          uri                     = optional(string)
          bucket_owner_account_id = optional(string)
        }))
      }))
      smithy_model = optional(object({
        inline_payload = optional(object({
          payload = string
        }))
        s3 = optional(object({
          uri                     = optional(string)
          bucket_owner_account_id = optional(string)
        }))
      }))
    }))
  })
  default = null
}

variable "gateway_target_timeouts" {
  description = "Timeout configuration for AgentCore gateway target operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# LAMBDA PERMISSION CONFIGURATION
# =============================================================================

variable "lambda_function_name" {
  description = "Name of the Lambda function to grant invoke permission for the gateway. When set, creates a Lambda permission and waits for propagation before creating the gateway target."
  type        = string
  default     = null
}


# =============================================================================
# TIMEOUT CONFIGURATION
# =============================================================================

variable "gateway_timeouts" {
  description = "Timeout configuration for AgentCore gateway operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# TAGGING CONFIGURATION
# =============================================================================

variable "core_tags" {
  description = "Default tags applied to all AWS resources created by this module"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to assign to all resources"
  type        = map(string)
  default     = {}
}