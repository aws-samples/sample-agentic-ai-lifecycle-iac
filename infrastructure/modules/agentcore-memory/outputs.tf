# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# MEMORY OUTPUTS
# =============================================================================

output "memory" {
  description = "Complete AgentCore memory resource"
  value       = try(aws_bedrockagentcore_memory.this[0], null)
}

output "memory_arn" {
  description = "ARN of the AgentCore memory"
  value       = try(aws_bedrockagentcore_memory.this[0].arn, null)
}

output "memory_id" {
  description = "ID of the AgentCore memory"
  value       = try(aws_bedrockagentcore_memory.this[0].id, null)
}

output "memory_name" {
  description = "Name of the AgentCore memory"
  value       = try(aws_bedrockagentcore_memory.this[0].name, null)
}

# =============================================================================
# MEMORY STRATEGY OUTPUTS
# =============================================================================

output "memory_strategy" {
  description = "Complete AgentCore memory strategy resource"
  value       = try(aws_bedrockagentcore_memory_strategy.this[0], null)
}

output "memory_strategy_id" {
  description = "ID of the AgentCore memory strategy"
  value       = try(aws_bedrockagentcore_memory_strategy.this[0].memory_strategy_id, null)
}

output "memory_strategy_name" {
  description = "Name of the AgentCore memory strategy"
  value       = try(aws_bedrockagentcore_memory_strategy.this[0].name, null)
}

output "memory_strategy_type" {
  description = "Type of the AgentCore memory strategy"
  value       = try(aws_bedrockagentcore_memory_strategy.this[0].type, null)
}

output "memory_strategy_namespaces" {
  description = "Namespaces of the AgentCore memory strategy"
  value       = try(aws_bedrockagentcore_memory_strategy.this[0].namespaces, null)
}