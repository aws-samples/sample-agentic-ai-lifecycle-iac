# Required
variable "agent_runtime_name" {
  description = "Name of the AgentCore runtime"
  type        = string
}

variable "agent_runtime_role_arn" {
  description = "ARN of the IAM role for the AgentCore runtime"
  type        = string
}

variable "agent_runtime_endpoint_name" {
  description = "Name of the AgentCore runtime endpoint"
  type        = string
}

# Artifact Configuration (choose one)
variable "container_uri" {
  description = "ECR container URI (required if code_configuration not provided)"
  type        = string
  default     = null
}

variable "code_configuration" {
  description = "S3 code configuration (alternative to container_uri)"
  type = object({
    entry_point   = list(string)
    runtime       = string
    s3_bucket     = string
    s3_prefix     = string
    s3_version_id = optional(string)
  })
  default = null
}

# Optional
variable "create_agent_runtime" {
  description = "Whether to create the AgentCore runtime"
  type        = bool
  default     = true
}

variable "create_agent_runtime_endpoint" {
  description = "Whether to create the runtime endpoint"
  type        = bool
  default     = true
}

variable "agent_runtime_description" {
  description = "Description of the AgentCore runtime"
  type        = string
  default     = null
}

variable "agent_runtime_environment_variables" {
  description = "Environment variables for the runtime"
  type        = map(string)
  default     = {}
}

variable "network_configuration" {
  description = "Network configuration (PUBLIC or VPC)"
  type = object({
    network_mode = string
    vpc_configuration = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
  })
  default = null
}

variable "authorizer_configuration" {
  description = "JWT authorization configuration"
  type = object({
    custom_jwt_authorizer = optional(object({
      discovery_url    = string
      allowed_audience = list(string)
      allowed_clients  = list(string)
    }))
  })
  default = null
}

variable "lifecycle_configuration" {
  description = "Lifecycle management configuration"
  type = object({
    idle_runtime_session_timeout = optional(number)
    max_lifetime                 = optional(number)
  })
  default = null
}

variable "protocol_configuration" {
  description = "Protocol configuration (HTTP, MCP, A2A)"
  type        = string
  default     = null
}

variable "request_header_configuration" {
  description = "Request header allowlist configuration"
  type = object({
    request_header_allowlist = optional(list(string))
  })
  default = null
}

variable "agent_runtime_timeouts" {
  description = "Timeout configuration for runtime operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "agent_runtime_endpoint_description" {
  description = "Description of the runtime endpoint"
  type        = string
  default     = null
}

variable "agent_runtime_endpoint_timeouts" {
  description = "Timeout configuration for endpoint operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}
