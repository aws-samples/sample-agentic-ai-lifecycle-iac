# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# API KEY PROVIDER OUTPUTS
# =============================================================================

output "api_key_provider" {
  description = "Complete AgentCore API key credential provider resource"
  value       = try(aws_bedrockagentcore_api_key_credential_provider.this[0], null)
  sensitive   = true
}

output "api_key_provider_arn" {
  description = "ARN of the AgentCore API key credential provider"
  value       = try(aws_bedrockagentcore_api_key_credential_provider.this[0].credential_provider_arn, null)
}

output "api_key_secret_arn" {
  description = "ARN of the API key secret"
  value       = try(aws_bedrockagentcore_api_key_credential_provider.this[0].api_key_secret_arn, null)
  sensitive   = true
}

# =============================================================================
# OAUTH2 PROVIDER OUTPUTS
# =============================================================================

output "oauth2_provider" {
  description = "Complete AgentCore OAuth2 credential provider resource"
  value       = try(aws_bedrockagentcore_oauth2_credential_provider.this[0], null)
  sensitive   = true
}

output "oauth2_provider_name" {
  description = "Name of the AgentCore OAuth2 credential provider"
  value       = try(aws_bedrockagentcore_oauth2_credential_provider.this[0].name, null)
}

output "oauth2_provider_arn" {
  description = "ARN of the AgentCore OAuth2 credential provider"
  value       = try(aws_bedrockagentcore_oauth2_credential_provider.this[0].credential_provider_arn, null)
}

output "oauth2_client_secret_arn" {
  description = "ARN of the OAuth2 client secret"
  value       = try(aws_bedrockagentcore_oauth2_credential_provider.this[0].client_secret_arn, null)
  sensitive   = true
}

# =============================================================================
# WORKLOAD IDENTITY OUTPUTS
# =============================================================================

output "workload_identity" {
  description = "Complete AgentCore workload identity resource"
  value       = try(aws_bedrockagentcore_workload_identity.this[0], null)
}

output "workload_identity_name" {
  description = "Name of the AgentCore workload identity"
  value       = try(aws_bedrockagentcore_workload_identity.this[0].name, null)
}

# =============================================================================
# TOKEN VAULT CMK OUTPUTS
# =============================================================================

output "token_vault_cmk" {
  description = "Complete AgentCore token vault CMK resource"
  value       = try(aws_bedrockagentcore_token_vault_cmk.this[0], null)
}

output "workload_identity_arn" {
  description = "ARN of the AgentCore workload identity"
  value       = try(aws_bedrockagentcore_workload_identity.this[0].workload_identity_arn, null)
}