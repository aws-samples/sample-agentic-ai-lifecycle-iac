# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# BROWSER OUTPUTS
# =============================================================================

output "browser" {
  description = "Complete AgentCore browser resource"
  value       = try(aws_bedrockagentcore_browser.this[0], null)
}

output "browser_id" {
  description = "ID of the AgentCore browser"
  value       = try(aws_bedrockagentcore_browser.this[0].browser_id, null)
}

output "browser_name" {
  description = "Name of the AgentCore browser"
  value       = try(aws_bedrockagentcore_browser.this[0].name, null)
}

output "browser_arn" {
  description = "ARN of the AgentCore browser"
  value       = try(aws_bedrockagentcore_browser.this[0].browser_arn, null)
}

# =============================================================================
# CODE INTERPRETER OUTPUTS
# =============================================================================

output "code_interpreter" {
  description = "Complete AgentCore code interpreter resource"
  value       = try(aws_bedrockagentcore_code_interpreter.this[0], null)
}

output "code_interpreter_id" {
  description = "ID of the AgentCore code interpreter"
  value       = try(aws_bedrockagentcore_code_interpreter.this[0].code_interpreter_id, null)
}

output "code_interpreter_name" {
  description = "Name of the AgentCore code interpreter"
  value       = try(aws_bedrockagentcore_code_interpreter.this[0].name, null)
}

output "code_interpreter_arn" {
  description = "ARN of the AgentCore code interpreter"
  value       = try(aws_bedrockagentcore_code_interpreter.this[0].code_interpreter_arn, null)
}