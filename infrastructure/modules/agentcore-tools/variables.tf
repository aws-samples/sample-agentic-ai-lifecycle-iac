# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AGENTCORE TOOLS VARIABLES
# =============================================================================
# Variables for configuring the AWS Bedrock AgentCore tools module.
# This module supports browser automation and code interpreter capabilities.
# =============================================================================

# =============================================================================
# BROWSER CONFIGURATION
# =============================================================================

variable "create_browser" {
  description = "Whether to create the AgentCore browser resource"
  type        = bool
  default     = false
}

variable "browser_name" {
  description = "Name of the AgentCore browser"
  type        = string
  default     = null
}

variable "browser_description" {
  description = "Description of the AgentCore browser"
  type        = string
  default     = null
}

variable "browser_execution_role_arn" {
  description = "ARN of the IAM role for browser execution"
  type        = string
  default     = null
}

variable "browser_network_configuration" {
  description = "Network configuration for the browser"
  type = object({
    network_mode = string
    vpc_config = optional(object({
      subnets         = list(string)
      security_groups = list(string)
    }))
  })
  default = null
}

variable "browser_recording" {
  description = "Recording configuration for browser sessions"
  type = object({
    enabled = optional(bool, false)
    s3_location = optional(object({
      bucket = string
      prefix = string
    }))
  })
  default = null
}

variable "browser_timeouts" {
  description = "Timeout configuration for browser operations"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# CODE INTERPRETER CONFIGURATION
# =============================================================================

variable "create_code_interpreter" {
  description = "Whether to create the AgentCore code interpreter resource"
  type        = bool
  default     = false
}

variable "code_interpreter_name" {
  description = "Name of the AgentCore code interpreter"
  type        = string
  default     = null
}

variable "code_interpreter_description" {
  description = "Description of the AgentCore code interpreter"
  type        = string
  default     = null
}

variable "code_interpreter_execution_role_arn" {
  description = "ARN of the IAM role for code interpreter execution"
  type        = string
  default     = null
}

variable "code_interpreter_network_configuration" {
  description = "Network configuration for the code interpreter"
  type = object({
    network_mode = string
    vpc_config = optional(object({
      subnets         = list(string)
      security_groups = list(string)
    }))
  })
  default = null
}



variable "code_interpreter_timeouts" {
  description = "Timeout configuration for code interpreter operations"
  type = object({
    create = optional(string)
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