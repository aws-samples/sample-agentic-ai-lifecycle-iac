# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AMAZON BEDROCK AGENTCORE IDENTITY MODULE
# =============================================================================
# This module creates AWS Bedrock AgentCore credential provider resources
# for authentication and authorization management.
# =============================================================================

# =============================================================================
# AGENTCORE API KEY CREDENTIAL PROVIDER RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_api_key_credential_provider" "this" {
  count    = var.create_api_key_provider ? 1 : 0
  provider = aws.target_region

  name = var.api_key_provider_name != null ? var.api_key_provider_name : "test-api-key-provider"
  
  # Use standard API key for compatibility with current provider versions
  api_key = var.api_key != null ? var.api_key : "placeholder-api-key"
}

# =============================================================================
# AGENTCORE OAUTH2 CREDENTIAL PROVIDER RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_oauth2_credential_provider" "this" {
  count    = var.create_oauth2_provider ? 1 : 0
  provider = aws.target_region

  name                       = var.oauth2_provider_name != null ? var.oauth2_provider_name : "test-oauth2-provider"
  credential_provider_vendor = var.oauth2_provider_vendor

  oauth2_provider_config {
    dynamic "custom_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.custom_oauth2_provider_config != null ? [1] : []
      content {
        # Standard credentials (mutually exclusive with write-only)
        client_id     = var.oauth2_provider_config.custom_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.custom_oauth2_provider_config.client_id : null
        client_secret = var.oauth2_provider_config.custom_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.custom_oauth2_provider_config.client_secret : null
        
        # Write-only credentials (recommended for production)
        client_id_wo                  = var.oauth2_provider_config.custom_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.custom_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.custom_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.custom_oauth2_provider_config.client_credentials_wo_version : null

        dynamic "oauth_discovery" {
          for_each = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery != null ? [1] : []
          content {
            discovery_url = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.discovery_url

            dynamic "authorization_server_metadata" {
              for_each = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.authorization_server_metadata != null ? [1] : []
              content {
                issuer                 = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.authorization_server_metadata.issuer
                authorization_endpoint = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.authorization_server_metadata.authorization_endpoint
                token_endpoint         = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.authorization_server_metadata.token_endpoint
                response_types         = var.oauth2_provider_config.custom_oauth2_provider_config.oauth_discovery.authorization_server_metadata.response_types
              }
            }
          }
        }
      }
    }

    dynamic "github_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.github_oauth2_provider_config != null ? [1] : []
      content {
        client_id                     = var.oauth2_provider_config.github_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.github_oauth2_provider_config.client_id : null
        client_secret                 = var.oauth2_provider_config.github_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.github_oauth2_provider_config.client_secret : null
        client_id_wo                  = var.oauth2_provider_config.github_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.github_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.github_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.github_oauth2_provider_config.client_credentials_wo_version : null
      }
    }

    dynamic "google_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.google_oauth2_provider_config != null ? [1] : []
      content {
        client_id                     = var.oauth2_provider_config.google_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.google_oauth2_provider_config.client_id : null
        client_secret                 = var.oauth2_provider_config.google_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.google_oauth2_provider_config.client_secret : null
        client_id_wo                  = var.oauth2_provider_config.google_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.google_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.google_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.google_oauth2_provider_config.client_credentials_wo_version : null
      }
    }

    dynamic "microsoft_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.microsoft_oauth2_provider_config != null ? [1] : []
      content {
        client_id                     = var.oauth2_provider_config.microsoft_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.microsoft_oauth2_provider_config.client_id : null
        client_secret                 = var.oauth2_provider_config.microsoft_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.microsoft_oauth2_provider_config.client_secret : null
        client_id_wo                  = var.oauth2_provider_config.microsoft_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.microsoft_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.microsoft_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.microsoft_oauth2_provider_config.client_credentials_wo_version : null
      }
    }

    dynamic "salesforce_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.salesforce_oauth2_provider_config != null ? [1] : []
      content {
        client_id                     = var.oauth2_provider_config.salesforce_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.salesforce_oauth2_provider_config.client_id : null
        client_secret                 = var.oauth2_provider_config.salesforce_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.salesforce_oauth2_provider_config.client_secret : null
        client_id_wo                  = var.oauth2_provider_config.salesforce_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.salesforce_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.salesforce_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.salesforce_oauth2_provider_config.client_credentials_wo_version : null
      }
    }

    dynamic "slack_oauth2_provider_config" {
      for_each = var.oauth2_provider_config != null && var.oauth2_provider_config.slack_oauth2_provider_config != null ? [1] : []
      content {
        client_id                     = var.oauth2_provider_config.slack_oauth2_provider_config.client_id_wo == null ? var.oauth2_provider_config.slack_oauth2_provider_config.client_id : null
        client_secret                 = var.oauth2_provider_config.slack_oauth2_provider_config.client_secret_wo == null ? var.oauth2_provider_config.slack_oauth2_provider_config.client_secret : null
        client_id_wo                  = var.oauth2_provider_config.slack_oauth2_provider_config.client_id_wo
        client_secret_wo              = var.oauth2_provider_config.slack_oauth2_provider_config.client_secret_wo
        client_credentials_wo_version = var.oauth2_provider_config.slack_oauth2_provider_config.client_id_wo != null ? var.oauth2_provider_config.slack_oauth2_provider_config.client_credentials_wo_version : null
      }
    }
  }
}

# =============================================================================
# AGENTCORE WORKLOAD IDENTITY RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_workload_identity" "this" {
  count    = var.create_workload_identity ? 1 : 0
  provider = aws.target_region

  name                                = var.workload_identity_name != null ? var.workload_identity_name : "test-workload-identity"
  allowed_resource_oauth2_return_urls = length(var.allowed_resource_oauth2_return_urls) > 0 ? var.allowed_resource_oauth2_return_urls : null
}

# =============================================================================
# AGENTCORE TOKEN VAULT CMK RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_token_vault_cmk" "this" {
  count    = var.create_token_vault_cmk ? 1 : 0
  provider = aws.target_region

  token_vault_id = var.token_vault_id

  kms_configuration {
    key_type    = var.kms_configuration.key_type
    kms_key_arn = var.kms_configuration.key_type == "CustomerManagedKey" ? var.kms_configuration.kms_key_arn : null
  }
}