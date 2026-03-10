# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# =============================================================================
# AMAZON BEDROCK AGENTCORE GATEWAY MODULE
# =============================================================================
# This module creates AWS Bedrock AgentCore gateway resources for API management,
# routing, and access control. It supports custom domains, authentication,
# rate limiting, and integration with AgentCore runtimes.
# =============================================================================

# =============================================================================
# AGENTCORE GATEWAY RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_gateway" "this" {
  count    = var.create_gateway ? 1 : 0
  provider = aws.target_region

  # Required attributes
  name            = var.gateway_name
  protocol_type   = var.protocol_type
  authorizer_type = var.authorizer_type
  role_arn        = var.gateway_role_arn

  # Optional attributes
  description     = var.gateway_description
  exception_level = var.exception_level
  kms_key_arn     = var.kms_key_arn

  # Authorizer Configuration
  dynamic "authorizer_configuration" {
    for_each = var.authorizer_configuration != null ? [var.authorizer_configuration] : []
    content {
      dynamic "custom_jwt_authorizer" {
        for_each = authorizer_configuration.value.custom_jwt_authorizer != null ? [authorizer_configuration.value.custom_jwt_authorizer] : []
        content {
          discovery_url    = custom_jwt_authorizer.value.discovery_url
          allowed_audience = custom_jwt_authorizer.value.allowed_audience
          allowed_clients  = custom_jwt_authorizer.value.allowed_clients
        }
      }
    }
  }

  # Protocol Configuration
  dynamic "protocol_configuration" {
    for_each = var.protocol_configuration != null ? [var.protocol_configuration] : []
    content {
      dynamic "mcp" {
        for_each = protocol_configuration.value.mcp != null ? [protocol_configuration.value.mcp] : []
        content {
          instructions       = mcp.value.instructions
          search_type        = mcp.value.search_type
          supported_versions = mcp.value.supported_versions
        }
      }
    }
  }

  # Interceptor Configuration
  dynamic "interceptor_configuration" {
    for_each = var.interceptor_configuration != null ? var.interceptor_configuration : []
    content {
      interception_points = interceptor_configuration.value.interception_points

      dynamic "input_configuration" {
        for_each = interceptor_configuration.value.input_configuration != null ? [interceptor_configuration.value.input_configuration] : []
        content {
          pass_request_headers = input_configuration.value.pass_request_headers
        }
      }

      dynamic "interceptor" {
        for_each = interceptor_configuration.value.interceptor != null ? [interceptor_configuration.value.interceptor] : []
        content {
          dynamic "lambda" {
            for_each = interceptor.value.lambda != null ? [interceptor.value.lambda] : []
            content {
              arn = lambda.value.arn
            }
          }
        }
      }
    }
  }

  # Timeouts
  dynamic "timeouts" {
    for_each = var.gateway_timeouts != null ? [var.gateway_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = merge(var.core_tags, var.tags)
}

# =============================================================================
# LAMBDA PERMISSION FOR GATEWAY
# =============================================================================
# When a Lambda function is used as a gateway target, the gateway's execution
# role needs invoke permission. This permission and sleep must live inside the
# module to avoid circular dependencies between the module and the caller.
# =============================================================================

resource "aws_lambda_permission" "gateway" {
  count    = var.create_gateway && var.lambda_function_name != null ? 1 : 0
  provider = aws.target_region

  statement_id  = "AllowBedrockAgentCoreInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "bedrock-agentcore.amazonaws.com"
  source_arn    = aws_bedrockagentcore_gateway.this[0].gateway_arn
}

resource "time_sleep" "wait_for_lambda_permission" {
  count           = var.create_gateway && var.lambda_function_name != null ? 1 : 0
  depends_on      = [aws_lambda_permission.gateway]
  create_duration = "10s"
}

# =============================================================================
# AGENTCORE GATEWAY TARGET RESOURCE
# =============================================================================

resource "aws_bedrockagentcore_gateway_target" "this" {
  count    = var.create_gateway_target ? 1 : 0
  provider = aws.target_region

  # Required attributes
  gateway_identifier = var.create_gateway ? aws_bedrockagentcore_gateway.this[0].gateway_id : var.gateway_identifier
  name               = var.gateway_target_name != null ? var.gateway_target_name : "${var.gateway_name}-target"

  # Optional attributes
  description = var.gateway_target_description

  # Credential Provider Configuration
  dynamic "credential_provider_configuration" {
    for_each = var.credential_provider_configuration != null ? [var.credential_provider_configuration] : []
    content {
      dynamic "gateway_iam_role" {
        for_each = credential_provider_configuration.value.gateway_iam_role != null ? [credential_provider_configuration.value.gateway_iam_role] : []
        content {}
      }

      dynamic "api_key" {
        for_each = credential_provider_configuration.value.api_key != null ? [credential_provider_configuration.value.api_key] : []
        content {
          provider_arn              = api_key.value.provider_arn
          credential_location       = api_key.value.credential_location
          credential_parameter_name = api_key.value.credential_parameter_name
          credential_prefix         = api_key.value.credential_prefix
        }
      }

      dynamic "oauth" {
        for_each = credential_provider_configuration.value.oauth != null ? [credential_provider_configuration.value.oauth] : []
        content {
          provider_arn      = oauth.value.provider_arn
          scopes            = oauth.value.scopes
          custom_parameters = oauth.value.custom_parameters
        }
      }
    }
  }

  # Target Configuration (required)
  target_configuration {
    dynamic "mcp" {
      for_each = var.target_configuration != null && var.target_configuration.mcp != null ? [var.target_configuration.mcp] : []
      content {
        dynamic "lambda" {
          for_each = mcp.value.lambda != null ? [mcp.value.lambda] : []
          content {
            lambda_arn = lambda.value.lambda_arn

            dynamic "tool_schema" {
              for_each = lambda.value.tool_schema != null ? [lambda.value.tool_schema] : []
              content {
                dynamic "inline_payload" {
                  for_each = tool_schema.value.inline_payload != null ? [tool_schema.value.inline_payload] : []
                  content {
                    name        = inline_payload.value.name
                    description = inline_payload.value.description

                    dynamic "input_schema" {
                      for_each = inline_payload.value.input_schema != null ? [inline_payload.value.input_schema] : []
                      content {
                        type        = input_schema.value.type
                        description = input_schema.value.description

                        dynamic "property" {
                          for_each = input_schema.value.property != null ? input_schema.value.property : []
                          content {
                            name        = property.value.name
                            type        = property.value.type
                            description = property.value.description
                            required    = property.value.required

                            dynamic "items" {
                              for_each = property.value.items != null ? [property.value.items] : []
                              content {
                                type        = items.value.type
                                description = items.value.description
                              }
                            }

                            dynamic "property" {
                              for_each = property.value.property != null ? property.value.property : []
                              content {
                                name        = property.value.name
                                type        = property.value.type
                                description = property.value.description
                                required    = property.value.required
                              }
                            }
                          }
                        }
                      }
                    }

                    dynamic "output_schema" {
                      for_each = inline_payload.value.output_schema != null ? [inline_payload.value.output_schema] : []
                      content {
                        type        = output_schema.value.type
                        description = output_schema.value.description

                        dynamic "property" {
                          for_each = output_schema.value.property != null ? output_schema.value.property : []
                          content {
                            name        = property.value.name
                            type        = property.value.type
                            description = property.value.description
                            required    = property.value.required
                          }
                        }
                      }
                    }
                  }
                }

                dynamic "s3" {
                  for_each = tool_schema.value.s3 != null ? [tool_schema.value.s3] : []
                  content {
                    uri                     = s3.value.uri
                    bucket_owner_account_id = s3.value.bucket_owner_account_id
                  }
                }
              }
            }
          }
        }

        dynamic "mcp_server" {
          for_each = mcp.value.mcp_server != null ? [mcp.value.mcp_server] : []
          content {
            endpoint = mcp_server.value.endpoint
          }
        }

        dynamic "open_api_schema" {
          for_each = mcp.value.open_api_schema != null ? [mcp.value.open_api_schema] : []
          content {
            dynamic "inline_payload" {
              for_each = open_api_schema.value.inline_payload != null ? [open_api_schema.value.inline_payload] : []
              content {
                payload = inline_payload.value.payload
              }
            }

            dynamic "s3" {
              for_each = open_api_schema.value.s3 != null ? [open_api_schema.value.s3] : []
              content {
                uri                     = s3.value.uri
                bucket_owner_account_id = s3.value.bucket_owner_account_id
              }
            }
          }
        }

        dynamic "smithy_model" {
          for_each = mcp.value.smithy_model != null ? [mcp.value.smithy_model] : []
          content {
            dynamic "inline_payload" {
              for_each = smithy_model.value.inline_payload != null ? [smithy_model.value.inline_payload] : []
              content {
                payload = inline_payload.value.payload
              }
            }

            dynamic "s3" {
              for_each = smithy_model.value.s3 != null ? [smithy_model.value.s3] : []
              content {
                uri                     = s3.value.uri
                bucket_owner_account_id = s3.value.bucket_owner_account_id
              }
            }
          }
        }
      }
    }
  }

  # Timeouts
  dynamic "timeouts" {
    for_each = var.gateway_target_timeouts != null ? [var.gateway_target_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [time_sleep.wait_for_lambda_permission]
}
