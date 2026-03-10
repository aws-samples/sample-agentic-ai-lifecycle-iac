# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# LOCAL VALUES
# =============================================================================
# Local values for the AgentCore Runtime module.
# Provides computed values and merged configurations.
# =============================================================================

locals {
  # Tag Management
  effective_tags = merge(
    var.tags
  )

  # Resource Naming
  runtime_name_prefix = var.agent_runtime_name != null ? "${var.agent_runtime_name}-" : ""

  # Resource Creation Flags
  create_runtime  = var.create_agent_runtime
  create_endpoint = var.create_agent_runtime_endpoint && local.create_runtime

  # Network Configuration
  is_vpc_deployment = try(var.network_configuration.network_mode == "VPC", false)

  # Validation Flags
  has_vpc_config = local.is_vpc_deployment && try(var.network_configuration.vpc_configuration != null, false)
}