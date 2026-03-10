# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# OUTPUTS
# =============================================================================

# Gateway outputs
output "gateway" {
  description = "Complete AgentCore gateway resource"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0] : null
  sensitive   = true
}

output "gateway_id" {
  description = "ID of the AgentCore gateway"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].gateway_id : null
}

output "gateway_arn" {
  description = "ARN of the AgentCore gateway"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].gateway_arn : null
}

output "gateway_name" {
  description = "Name of the AgentCore gateway"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].name : null
}

output "gateway_endpoint" {
  description = "Endpoint URL of the AgentCore gateway"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].gateway_url : null
}

output "gateway_workload_identity_details" {
  description = "Workload identity details of the AgentCore gateway"
  value       = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].workload_identity_details : null
}

# Gateway Target outputs
output "gateway_target" {
  description = "Complete AgentCore gateway target resource"
  value       = var.create_gateway_target ? aws_bedrockagentcore_gateway_target.this[0] : null
  sensitive   = true
}

output "gateway_target_id" {
  description = "ID of the AgentCore gateway target"
  value       = var.create_gateway_target ? aws_bedrockagentcore_gateway_target.this[0].target_id : null
}

output "gateway_target_name" {
  description = "Name of the AgentCore gateway target"
  value       = var.create_gateway_target ? aws_bedrockagentcore_gateway_target.this[0].name : null
}
