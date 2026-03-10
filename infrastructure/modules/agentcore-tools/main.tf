# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AMAZON BEDROCK AGENTCORE TOOLS MODULE
# =============================================================================
# This module creates AWS Bedrock AgentCore tool resources including browser
# automation and code interpreter capabilities for agent workflows.
# =============================================================================

# =============================================================================
# AGENTCORE BROWSER RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_browser" "this" {
  count    = var.create_browser ? 1 : 0
  provider = aws.target_region

  name               = var.browser_name
  description        = var.browser_description
  execution_role_arn = var.browser_execution_role_arn

  network_configuration {
    network_mode = var.browser_network_configuration != null ? var.browser_network_configuration.network_mode : "PUBLIC"

    dynamic "vpc_config" {
      for_each = try(var.browser_network_configuration.network_mode == "VPC" && var.browser_network_configuration.vpc_config != null, false) ? [1] : []
      content {
        subnets         = var.browser_network_configuration.vpc_config.subnets
        security_groups = var.browser_network_configuration.vpc_config.security_groups
      }
    }
  }

  dynamic "recording" {
    for_each = var.browser_recording != null ? [1] : []
    content {
      enabled = var.browser_recording.enabled

      dynamic "s3_location" {
        for_each = var.browser_recording.s3_location != null ? [1] : []
        content {
          bucket = var.browser_recording.s3_location.bucket
          prefix = var.browser_recording.s3_location.prefix
        }
      }
    }
  }

  tags = local.effective_tags
}

# =============================================================================
# AGENTCORE CODE INTERPRETER RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_code_interpreter" "this" {
  count    = var.create_code_interpreter ? 1 : 0
  provider = aws.target_region

  name               = var.code_interpreter_name
  description        = var.code_interpreter_description
  execution_role_arn = var.code_interpreter_execution_role_arn

  network_configuration {
    network_mode = var.code_interpreter_network_configuration != null ? var.code_interpreter_network_configuration.network_mode : "PUBLIC"

    dynamic "vpc_config" {
      for_each = try(var.code_interpreter_network_configuration.network_mode == "VPC" && var.code_interpreter_network_configuration.vpc_config != null, false) ? [1] : []
      content {
        subnets         = var.code_interpreter_network_configuration.vpc_config.subnets
        security_groups = var.code_interpreter_network_configuration.vpc_config.security_groups
      }
    }
  }

  tags = local.effective_tags
}