# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# Amazon Bedrock AgentCore Memory Module

# AgentCore Memory
resource "aws_bedrockagentcore_memory" "this" {
  count    = var.create_memory ? 1 : 0
  provider = aws.target_region

  name                      = var.memory_name
  description               = var.memory_description
  event_expiry_duration     = var.memory_event_expiry_duration
  encryption_key_arn        = var.memory_encryption_key_arn
  memory_execution_role_arn = var.memory_execution_role_arn
  region                    = var.memory_region

  dynamic "timeouts" {
    for_each = var.memory_timeouts != null ? [var.memory_timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }

  tags = local.effective_tags
}

# AgentCore Memory Strategy
resource "aws_bedrockagentcore_memory_strategy" "this" {
  count    = var.create_memory_strategy ? 1 : 0
  provider = aws.target_region

  memory_id                 = aws_bedrockagentcore_memory.this[0].id
  name                      = var.memory_strategy_name
  type                      = var.memory_strategy_type
  namespaces                = var.memory_strategy_namespaces
  description               = var.memory_strategy_description
  region                    = var.memory_strategy_region
  memory_execution_role_arn = var.memory_strategy_execution_role_arn

  dynamic "configuration" {
    for_each = var.memory_strategy_configuration != null ? [1] : []
    content {
      type = var.memory_strategy_configuration.type

      dynamic "consolidation" {
        for_each = var.memory_strategy_configuration.consolidation != null ? [1] : []
        content {
          append_to_prompt = var.memory_strategy_configuration.consolidation.append_to_prompt
          model_id         = var.memory_strategy_configuration.consolidation.model_id
        }
      }

      dynamic "extraction" {
        for_each = var.memory_strategy_configuration.extraction != null ? [1] : []
        content {
          append_to_prompt = var.memory_strategy_configuration.extraction.append_to_prompt
          model_id         = var.memory_strategy_configuration.extraction.model_id
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = var.memory_strategy_timeouts != null ? [var.memory_strategy_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
