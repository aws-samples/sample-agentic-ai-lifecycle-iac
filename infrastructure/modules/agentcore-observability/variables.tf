# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# REQUIRED PARAMETERS
# =============================================================================

variable "resource_name" {
  description = "Name of the AgentCore resource (runtime, memory, gateway, etc.)"
  type        = string
}

# =============================================================================
# OPTIONAL PARAMETERS
# =============================================================================


variable "xray_sampling_rule" {
  description = "X-Ray sampling rule configuration (optional)"
  type = object({
    rule_name      = string
    priority       = optional(number, 9999)
    version        = optional(number, 1)
    reservoir_size = optional(number, 1)
    fixed_rate     = optional(number, 0.05)
    url_path       = optional(string, "*")
    host           = optional(string, "*")
    http_method    = optional(string, "*")
    service_type   = optional(string, "*")
    service_name   = string
    resource_arn   = optional(string, "*")
  })
  default = null

  validation {
    condition     = var.xray_sampling_rule == null || (var.xray_sampling_rule.fixed_rate >= 0 && var.xray_sampling_rule.fixed_rate <= 1)
    error_message = "X-Ray fixed_rate must be between 0 and 1."
  }

  validation {
    condition     = var.xray_sampling_rule == null || (var.xray_sampling_rule.priority >= 1 && var.xray_sampling_rule.priority <= 9999)
    error_message = "X-Ray priority must be between 1 and 9999."
  }
}

variable "log_deliveries" {
  description = "Map of log delivery configurations. Key is the delivery name, value contains source and destination config"
  type = map(object({
    resource_arn             = string
    log_type                 = string # TRACES, USAGE_LOGS, APPLICATION_LOGS
    destination_type         = string # XRAY, CWL, S3
    destination_resource_arn = optional(string)
  }))
  default = {}
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "core_tags" {
  description = "Default tags applied to all AWS resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to assign to all resources"
  type        = map(string)
  default     = {}
}
