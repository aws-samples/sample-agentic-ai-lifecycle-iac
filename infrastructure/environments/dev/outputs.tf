# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.
# Outputs for Complete AgentCore Demo

# =============================================================================
# RUNTIME OUTPUTS
# =============================================================================

output "agent_runtime_id" {
  description = "Agent runtime ID"
  value       = module.agentcore_runtime.agent_runtime_id
}

output "agent_runtime_arn" {
  description = "Agent runtime ARN"
  value       = module.agentcore_runtime.agent_runtime_arn
}

output "agent_runtime_endpoint" {
  description = "Agent runtime endpoint"
  value       = module.agentcore_runtime.agent_runtime_endpoint_arn
}

output "agent_runtime_endpoint_arn" {
description = "Agent runtime endpoint ARN"
value = module.agentcore_runtime.agent_runtime_endpoint_arn
}

# =============================================================================
# MEMORY OUTPUTS
# =============================================================================

output "memory_id" {
  description = "Memory ID"
  value       = module.agentcore_memory.memory_id
}

output "memory_arn" {
  description = "Memory ARN"
  value       = module.agentcore_memory.memory_arn
}

# =============================================================================
# GATEWAY OUTPUTS
# =============================================================================

output "gateway_id" {
  description = "Gateway ID"
  value       = module.agentcore_gateway.gateway_id
}

output "gateway_url" {
  description = "Gateway endpoint URL"
  value       = module.agentcore_gateway.gateway_endpoint
}

output "gateway_arn" {
  description = "Gateway ARN"
  value       = module.agentcore_gateway.gateway_arn
}

# =============================================================================
# TOOLS OUTPUTS
# =============================================================================

output "browser_id" {
  description = "Browser tool ID"
  value       = module.agentcore_tools.browser_id
}

output "code_interpreter_id" {
  description = "Code interpreter ID"
  value       = module.agentcore_tools.code_interpreter_id
}

# =============================================================================
# IDENTITY OUTPUTS
# =============================================================================

output "workload_identity_name" {
  description = "Workload identity name"
  value       = module.agentcore_identity.workload_identity_name
  sensitive   = true
}

output "api_key_provider_arn" {
  description = "API key provider ARN"
  value       = module.agentcore_identity.api_key_provider_arn
  sensitive   = true
}

output "oauth2_provider_arn" {
  description = "OAuth2 provider ARN"
  value       = module.agentcore_identity.oauth2_provider_arn
}

# =============================================================================
# COGNITO OUTPUTS
# =============================================================================

# output "cognito_user_pool_id" {
#   description = "Cognito user pool ID"
#   value       = aws_cognito_user_pool.identity.id
# }

# output "cognito_domain" {
#   description = "Cognito domain"
#   value       = aws_cognito_user_pool_domain.identity.domain
# }

# output "m2m_client_id" {
#   description = "Machine-to-machine client ID"
#   value       = aws_cognito_user_pool_client.m2m_client.id
# }

# output "m2m_client_secret" {
#   description = "Machine-to-machine client secret"
#   value       = aws_cognito_user_pool_client.m2m_client.client_secret
#   sensitive   = true
# }

# output "token_endpoint" {
#   description = "OAuth2 token endpoint"
#   value       = "https://${aws_cognito_user_pool_domain.identity.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
# }

# output "oauth_scope" {
#   description = "OAuth scope for API access"
#   value       = "${aws_cognito_resource_server.api.identifier}/read ${aws_cognito_resource_server.api.identifier}/write"
# }


