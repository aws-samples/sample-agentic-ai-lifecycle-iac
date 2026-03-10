# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AGENTCORE MEMORY VARIABLES
# =============================================================================
# Variables for configuring the AWS Bedrock AgentCore memory module.
# This module supports memory management, strategy configuration,
# and integration with AgentCore runtimes.
# =============================================================================

# =============================================================================
# MEMORY CONFIGURATION
# =============================================================================

variable "create_memory" {
  description = "Whether to create the AgentCore memory"
  type        = bool
  default     = true
}

variable "memory_name" {
  description = "Name of the AgentCore memory"
  type        = string
  default     = null
}

variable "memory_description" {
  description = "Description of the AgentCore memory"
  type        = string
  default     = null
}

variable "memory_event_expiry_duration" {
  description = "Event expiry duration for the AgentCore memory (in days)"
  type        = number
  default     = 30
}

variable "memory_encryption_key_arn" {
  description = "ARN of the KMS key used to encrypt the memory"
  type        = string
  default     = null
}

variable "memory_execution_role_arn" {
  description = "ARN of the IAM role that the memory service assumes"
  type        = string
  default     = null
}

variable "memory_client_token" {
  description = "Unique client token for idempotent memory creation"
  type        = string
  default     = null
}

variable "memory_region" {
  description = "AWS region for the memory resource"
  type        = string
  default     = null
}

variable "memory_timeouts" {
  description = "Timeout configuration for AgentCore memory operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# MEMORY STRATEGY CONFIGURATION
# =============================================================================

variable "create_memory_strategy" {
  description = "Whether to create the AgentCore memory strategy"
  type        = bool
  default     = false
}


variable "memory_strategy_name" {
  description = "Name of the AgentCore memory strategy"
  type        = string
  default     = null
}

variable "memory_strategy_description" {
  description = "Description of the AgentCore memory strategy"
  type        = string
  default     = null
}

variable "memory_strategy_type" {
  description = "Type of the AgentCore memory strategy"
  type        = string
  default     = "SEMANTIC"
}

variable "memory_strategy_namespaces" {
  description = "Namespaces for the AgentCore memory strategy. Must be non-empty to isolate application sessions and resources per GCS-BRAC-IAM-04."
  type        = list(string)

  validation {
    condition     = length(var.memory_strategy_namespaces) > 0
    error_message = "[GCS-BRAC-IAM-04] Namespaces MUST be provided and cannot be empty. Namespaces are required to isolate application sessions and resources within AgentCore to enhance application-level security and prevent data leakage across tenants or user sessions."
  }

  validation {
    condition     = alltrue([for ns in var.memory_strategy_namespaces : ns != "" && ns != null])
    error_message = "[GCS-BRAC-IAM-04] All namespace values must be non-empty strings. Empty or null namespace values are not allowed."
  }
}

variable "memory_strategy_configuration" {
  description = "Custom configuration for CUSTOM type memory strategies"
  type = object({
    type = string # SEMANTIC_OVERRIDE, SUMMARY_OVERRIDE, USER_PREFERENCE_OVERRIDE
    consolidation = optional(object({
      append_to_prompt = string
      model_id         = string
    }))
    extraction = optional(object({
      append_to_prompt = string
      model_id         = string
    }))
  })
  default = null
}

variable "memory_strategy_region" {
  description = "AWS region for the memory strategy resource"
  type        = string
  default     = null
}

variable "memory_strategy_execution_role_arn" {
  description = "ARN of the IAM role for CUSTOM strategy model processing"
  type        = string
  default     = null
}

variable "memory_strategy_timeouts" {
  description = "Timeout configuration for AgentCore memory strategy operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# GENERAL CONFIGURATION
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