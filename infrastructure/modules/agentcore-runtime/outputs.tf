output "agent_runtime_arn" {
  description = "ARN of the AgentCore runtime"
  value       = try(aws_bedrockagentcore_agent_runtime.this[0].agent_runtime_arn, null)
}

output "agent_runtime_id" {
  description = "ID of the AgentCore runtime"
  value       = try(aws_bedrockagentcore_agent_runtime.this[0].agent_runtime_id, null)
}

output "agent_runtime_version" {
  description = "Version of the AgentCore runtime"
  value       = try(aws_bedrockagentcore_agent_runtime.this[0].agent_runtime_version, null)
}

output "agent_runtime_endpoint_arn" {
  description = "ARN of the runtime endpoint"
  value       = try(aws_bedrockagentcore_agent_runtime_endpoint.this[0].agent_runtime_endpoint_arn, null)
}
