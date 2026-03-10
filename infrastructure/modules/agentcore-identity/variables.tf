# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AGENTCORE IDENTITY VARIABLES
# =============================================================================
# Variables for configuring the AWS Bedrock AgentCore credential providers.
# This module supports API key providers, OAuth2 providers, and workload identity
# for AgentCore applications.
# =============================================================================

# =============================================================================
# API KEY CREDENTIAL PROVIDER CONFIGURATION
# =============================================================================

variable "create_api_key_provider" {
  description = "Whether to create the AgentCore API key credential provider"
  type        = bool
  default     = true
}

variable "api_key_provider_name" {
  description = "Name of the AgentCore API key credential provider"
  type        = string
  default     = null
}


variable "api_key" {
  description = "API key for the credential provider"
  type        = string
  default     = null
  sensitive   = true
}

variable "api_key_wo" {
  description = "Write-only API key for the credential provider (recommended for production). Cannot be used with api_key. Must be used together with api_key_wo_version."
  type        = string
  default     = null
  sensitive   = true

}

variable "api_key_wo_version" {
  description = "Version number for write-only API key updates. Required when using api_key_wo."
  type        = number
  default     = null

}



# =============================================================================
# OAUTH2 CREDENTIAL PROVIDER CONFIGURATION
# =============================================================================

variable "create_oauth2_provider" {
  description = "Whether to create the AgentCore OAuth2 credential provider"
  type        = bool
  default     = false
}

variable "oauth2_provider_name" {
  description = "Name of the AgentCore OAuth2 credential provider"
  type        = string
  default     = null
}


variable "oauth2_provider_vendor" {
  description = "Vendor of the OAuth2 credential provider"
  type        = string
  default     = "CustomOauth2"

}

variable "oauth2_provider_config" {
  description = "OAuth2 provider configuration. Must contain exactly one provider type."
  type = object({
    custom_oauth2_provider_config = optional(object({
      # Standard credentials (mutually exclusive with write-only)
      client_id     = optional(string)
      client_secret = optional(string)
      # Write-only credentials (recommended for production)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
      oauth_discovery = optional(object({
        # Mutually exclusive options
        discovery_url = optional(string)
        authorization_server_metadata = optional(object({
          issuer                 = string
          authorization_endpoint = string
          token_endpoint         = string
          response_types         = optional(list(string))
        }))
      }))
    }))
    github_oauth2_provider_config = optional(object({
      # Standard credentials (mutually exclusive with write-only)
      client_id     = optional(string)
      client_secret = optional(string)
      # Write-only credentials (recommended for production)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
    }))
    google_oauth2_provider_config = optional(object({
      client_id                     = optional(string)
      client_secret                 = optional(string)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
    }))
    microsoft_oauth2_provider_config = optional(object({
      client_id                     = optional(string)
      client_secret                 = optional(string)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
    }))
    salesforce_oauth2_provider_config = optional(object({
      client_id                     = optional(string)
      client_secret                 = optional(string)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
    }))
    slack_oauth2_provider_config = optional(object({
      client_id                     = optional(string)
      client_secret                 = optional(string)
      client_id_wo                  = optional(string)
      client_secret_wo              = optional(string)
      client_credentials_wo_version = optional(number)
    }))
  })
  default = null

}


# =============================================================================
# WORKLOAD IDENTITY CONFIGURATION
# =============================================================================

variable "create_workload_identity" {
  description = "Whether to create the AgentCore workload identity"
  type        = bool
  default     = false
}

variable "workload_identity_name" {
  description = "Name of the AgentCore workload identity"
  type        = string
  default     = null

}


variable "allowed_resource_oauth2_return_urls" {
  description = "Set of allowed OAuth2 return URLs for resources associated with this workload identity"
  type        = list(string)
  default     = []

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

# =============================================================================
# TOKEN VAULT CMK CONFIGURATION
# =============================================================================

variable "create_token_vault_cmk" {
  description = "Whether to create the AgentCore token vault CMK"
  type        = bool
  default     = false
}

variable "token_vault_id" {
  description = "Token vault ID"
  type        = string
  default     = "default"
}

variable "kms_configuration" {
  description = "KMS configuration for the token vault"
  type = object({
    key_type    = string
    kms_key_arn = optional(string)
  })
  default = null


}