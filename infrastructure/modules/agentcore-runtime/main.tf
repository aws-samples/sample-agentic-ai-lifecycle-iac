resource "aws_bedrockagentcore_agent_runtime" "this" {
  count    = var.create_agent_runtime ? 1 : 0
  provider = aws.target_region

  agent_runtime_name    = var.agent_runtime_name
  role_arn              = var.agent_runtime_role_arn
  description           = var.agent_runtime_description
  environment_variables = length(var.agent_runtime_environment_variables) > 0 ? var.agent_runtime_environment_variables : null

  agent_runtime_artifact {
    dynamic "container_configuration" {
      for_each = var.container_uri != null ? [1] : []
      content {
        container_uri = var.container_uri
      }
    }

    dynamic "code_configuration" {
      for_each = var.code_configuration != null ? [1] : []
      content {
        entry_point = var.code_configuration.entry_point
        runtime     = var.code_configuration.runtime
        code {
          s3 {
            bucket     = var.code_configuration.s3_bucket
            prefix     = var.code_configuration.s3_prefix
            version_id = var.code_configuration.s3_version_id
          }
        }
      }
    }
  }

  network_configuration {
    network_mode = var.network_configuration != null ? var.network_configuration.network_mode : "PUBLIC"

    dynamic "network_mode_config" {
      for_each = try(var.network_configuration.network_mode == "VPC" && var.network_configuration.vpc_configuration != null, false) ? [1] : []
      content {
        subnets         = var.network_configuration.vpc_configuration.subnet_ids
        security_groups = var.network_configuration.vpc_configuration.security_group_ids
      }
    }
  }

  dynamic "authorizer_configuration" {
    for_each = var.authorizer_configuration != null ? [1] : []
    content {
      dynamic "custom_jwt_authorizer" {
        for_each = var.authorizer_configuration.custom_jwt_authorizer != null ? [1] : []
        content {
          discovery_url    = var.authorizer_configuration.custom_jwt_authorizer.discovery_url
          allowed_audience = var.authorizer_configuration.custom_jwt_authorizer.allowed_audience
          allowed_clients  = var.authorizer_configuration.custom_jwt_authorizer.allowed_clients
        }
      }
    }
  }

  dynamic "lifecycle_configuration" {
    for_each = var.lifecycle_configuration != null ? [1] : []
    content {
      idle_runtime_session_timeout = var.lifecycle_configuration.idle_runtime_session_timeout
      max_lifetime                 = var.lifecycle_configuration.max_lifetime
    }
  }

  dynamic "protocol_configuration" {
    for_each = var.protocol_configuration != null ? [1] : []
    content {
      server_protocol = var.protocol_configuration
    }
  }

  dynamic "request_header_configuration" {
    for_each = var.request_header_configuration != null ? [1] : []
    content {
      request_header_allowlist = var.request_header_configuration.request_header_allowlist
    }
  }

  dynamic "timeouts" {
    for_each = var.agent_runtime_timeouts != null ? [var.agent_runtime_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = var.tags
}

resource "aws_bedrockagentcore_agent_runtime_endpoint" "this" {
  count    = var.create_agent_runtime_endpoint ? 1 : 0
  provider = aws.target_region

  agent_runtime_id      = aws_bedrockagentcore_agent_runtime.this[0].agent_runtime_id
  name                  = var.agent_runtime_endpoint_name
  agent_runtime_version = aws_bedrockagentcore_agent_runtime.this[0].agent_runtime_version
  description           = var.agent_runtime_endpoint_description

  dynamic "timeouts" {
    for_each = var.agent_runtime_endpoint_timeouts != null ? [var.agent_runtime_endpoint_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = var.tags
}
