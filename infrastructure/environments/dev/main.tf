# Complete AgentCore Demo with All Components
# This includes: Runtime, Memory, Gateway, Identity, Tools, Observability, Cognito, Lambda, CodeBuild

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# KMS KEY FOR AGENTCORE ENCRYPTION
# =============================================================================

resource "aws_kms_key" "agentcore" {
  provider                = aws.primary_region
  description             = "KMS key for AgentCore encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project = "agentcore"
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AgentCore Services"
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Gateway Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.gateway_execution.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Gateway Assumed Role Sessions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "${aws_iam_role.gateway_execution.arn}/*"
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/*"
          }
        }
      }
    ]
  })

}

resource "aws_kms_alias" "agentcore" {
  provider      = aws.primary_region
  name          = "alias/${local.name_prefix}agentcore"
  target_key_id = aws_kms_key.agentcore.key_id
}

# =============================================================================
# SECURITY GROUP FOR VPC DEPLOYMENT (OPTIONAL)
# =============================================================================

resource "aws_security_group" "agentcore" {
  #checkov:skip=CKV2_AWS_5:Security group is attached to AgentCore runtime via module
  #checkov:skip=CKV_AWS_382:AgentCore requires outbound access to AWS services across multiple ports and protocols
  count    = var.vpc_name != null ? 1 : 0
  provider = aws.primary_region

  name_prefix = "${local.name_prefix}agentcore-"
  description = "Security group for Bedrock AgentCore runtime"
  vpc_id      = data.aws_vpc.existing[0].id

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}agentcore-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# =============================================================================
# LAMBDA FUNCTION FOR GATEWAY TARGET
# =============================================================================

resource "aws_iam_role" "lambda_execution" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

}

# Lambda VPC Execution Role (if Lambda is in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  provider   = aws.primary_region
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  provider   = aws.primary_region
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  provider   = aws.primary_region
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/lambda-functions"
}

# Dead Letter Queue for Lambda
resource "aws_sqs_queue" "lambda_dlq" {
  provider                  = aws.primary_region
  name                      = "${local.name_prefix}-lambda-dlq"
  message_retention_seconds = 1209600 # 14 days
  kms_master_key_id         = aws_kms_key.agentcore.id
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "lambda_dlq" {
  provider  = aws.primary_region
  queue_url = aws_sqs_queue.lambda_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}-policy-lookup"
          }
        }
      }
    ]
  })
}

# IAM policy for Lambda to send to DLQ
resource "aws_iam_role_policy" "lambda_dlq" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-lambda-dlq-policy"
  role     = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

# Security group for Lambda gateway target function
resource "aws_security_group" "lambda_gateway_target" {
  #checkov:skip=CKV2_AWS_5:Security group is attached to Lambda function via vpc_config
  count       = var.vpc_name != null ? 1 : 0
  provider    = aws.primary_region
  name        = "${local.name_prefix}lambda-gateway-target-sg"
  description = "Security group for Lambda gateway target function"
  vpc_id      = data.aws_vpc.existing[0].id

  egress {
    description = "Allow all outbound traffic for Lambda function"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  #checkov:skip=CKV_AWS_382:Lambda requires internet access for AWS services
}

# Lambda Code Signing Configuration
resource "aws_lambda_code_signing_config" "policy_lookup" {
  provider = aws.primary_region

  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }

  description = "Code signing config for ${local.name_prefix}-policy-lookup"
}

resource "aws_signer_signing_profile" "lambda" {
  provider    = aws.primary_region
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = replace("${local.name_prefix}", "-", "_")
}

resource "aws_lambda_function" "policy_lookup" {
  provider         = aws.primary_region
  filename         = data.archive_file.lambda.output_path
  function_name    = "${local.name_prefix}-policy-lookup"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "policy_lookup.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30

  # Code signing validation
  code_signing_config_arn = aws_lambda_code_signing_config.policy_lookup.arn

  # KMS encryption for environment variables
  kms_key_arn = aws_kms_key.agentcore.arn

  # VPC configuration (when VPC is available)
  dynamic "vpc_config" {
    for_each = var.vpc_name != null ? [1] : []
    content {
      subnet_ids         = data.aws_subnets.existing[0].ids
      security_group_ids = [aws_security_group.lambda_gateway_target[0].id]
    }
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  # X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Dead Letter Queue
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # Concurrency limit
  reserved_concurrent_executions = 10


  depends_on = [
    aws_iam_role_policy.lambda_dlq,
    aws_iam_role_policy_attachment.lambda_xray,
    aws_sqs_queue_policy.lambda_dlq
  ]
}

# =============================================================================
# IAM ROLES FOR GATEWAY
# =============================================================================

resource "aws_iam_role" "gateway_execution" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-gateway-execution-role"

  #permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.id}:policy/mandatory-permissions-boundary-01"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_role_policy" "gateway_execution" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-gateway-execution-policy"
  role     = aws_iam_role.gateway_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.policy_lookup.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.agentcore.arn
      }
    ]
  })
}

# =============================================================================
# IAM ROLE FOR AGENT RUNTIME
# =============================================================================

resource "aws_iam_role" "agent_execution" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-agent-execution-role"

  #permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.id}:policy/mandatory-permissions-boundary-01"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock-agentcore.amazonaws.com"
      }
    }]
  })

}

resource "aws_iam_role_policy_attachment" "agent_execution_managed" {
  provider   = aws.primary_region
  role       = aws_iam_role.agent_execution.name
  policy_arn = "arn:aws:iam::aws:policy/BedrockAgentCoreFullAccess"
}

resource "aws_iam_role_policy" "agent_execution" {
  provider = aws.primary_region
  name     = "${local.name_prefix}-agent-execution-policy"
  role     = aws_iam_role.agent_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.agentcore.arn
      },
      {
        # nosemgrep: terraform.lang.security.iam.no-iam-data-exfiltration.no-iam-data-exfiltration
        # Scoped to specific secret paths to enforce least privilege.
        # Wildcards (-*) account for the random suffix AWS appends to secret ARNs.
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:agentcore/config-*",
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:agentcore/db-credentials-*",
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:agentcore/api-keys-*"
        ]
      },
      {
        # Allow the agent to apply Bedrock Guardrails during ConverseStream calls
        Effect = "Allow"
        Action = [
          "bedrock:ApplyGuardrail"
        ]
        Resource = aws_bedrock_guardrail.example.guardrail_arn
      },
      {
        # Allow the agent to invoke Bedrock foundation models (required for Strands agent
        # ConverseStream calls and browser-use BrowserAgent LLM calls)
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/us.anthropic.claude-sonnet-4-20250514-v1:0",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/us.anthropic.claude-3-7-sonnet-20250219-v1:0"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken" # nosemgrep: terraform.lang.security.iam.no-iam-creds-exposure.no-iam-creds-exposure - AWS requirement, cannot scope to specific resource
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/agentcore-*"
      }
    ]
  })
}

# =============================================================================
# AGENTCORE TOOLS MODULE
# =============================================================================

module "agentcore_tools" {
  source = "../../modules/agentcore-tools"

  create_browser      = true
  browser_name        = replace("${local.name_prefix}_browser", "-", "_")
  browser_description = "Browser tool for agent"

  create_code_interpreter      = true
  code_interpreter_name        = replace("${local.name_prefix}_code_interpreter", "-", "_")
  code_interpreter_description = "Code interpreter for agent"


  providers = {
    aws.target_region = aws.primary_region
  }
}

# =============================================================================
# AGENTCORE MEMORY MODULE
# =============================================================================

module "agentcore_memory" {
  source = "../../modules/agentcore-memory"

  create_memory             = true
  memory_name               = replace("${local.name_prefix}_memory", "-", "_")
  memory_description        = "Memory for agent"
  memory_encryption_key_arn = aws_kms_key.agentcore.arn

  create_memory_strategy      = true
  memory_strategy_name        = "UserPreferenceLearner"
  memory_strategy_type        = "USER_PREFERENCE"
  memory_strategy_description = "Learn user preferences"
  memory_strategy_namespaces  = ["/preferences/{actorId}"]


  providers = {
    aws.target_region = aws.primary_region
  }
}

# =============================================================================
# AGENTCORE IDENTITY MODULE
# =============================================================================

module "agentcore_identity" {
  source = "../../modules/agentcore-identity"

  create_api_key_provider = false
  api_key_provider_name   = "${local.name_prefix}-api-key-provider"
  api_key                 = var.api_key

  create_workload_identity = true
  workload_identity_name   = "${local.name_prefix}-workload-identity"

  # OAuth2 Credential Provider for Cognito
  create_oauth2_provider = false
  oauth2_provider_name   = "${local.name_prefix}-oauth2-provider"
  oauth2_provider_vendor = "CustomOauth2"
  # oauth2_provider_config   = {
  #   custom_oauth2_provider_config = {
  #     client_id     = aws_cognito_user_pool_client.m2m_client.id
  #     client_secret = aws_cognito_user_pool_client.m2m_client.client_secret
  #     oauth_discovery = {
  #       authorization_server_metadata = {
  #         issuer                 = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.identity.id}"
  #         authorization_endpoint = "https://${aws_cognito_user_pool_domain.identity.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
  #         token_endpoint         = "https://${aws_cognito_user_pool_domain.identity.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
  #       }
  #     }
  #   }
  # }


  providers = {
    aws.target_region = aws.primary_region
  }
}

# =============================================================================
# AGENTCORE GATEWAY MODULE
# =============================================================================

module "agentcore_gateway" {
  source = "../../modules/agentcore-gateway"

  # Gateway
  create_gateway      = true
  gateway_name        = "${local.name_prefix}gateway"
  gateway_description = "Gateway for weather API with IAM Auth (No Cognito)"
  gateway_role_arn    = aws_iam_role.gateway_execution.arn
  kms_key_arn         = aws_kms_key.agentcore.arn

  # IAM Authorization (replaces Cognito OAuth)
  authorizer_type = "AWS_IAM"

  # Lambda permission (managed inside module to avoid circular dependency)
  lambda_function_name = aws_lambda_function.policy_lookup.function_name

  # Gateway Target - Policy Lookup (MCP protocol)
  create_gateway_target      = true
  gateway_target_name        = "policy-lookup-target"
  gateway_target_description = "Policy document lookup"

  credential_provider_configuration = {
    gateway_iam_role = {}
  }

  target_configuration = {
    mcp = {
      lambda = {
        lambda_arn = try(aws_lambda_function.policy_lookup.arn, null)
        tool_schema = {
          inline_payload = {
            name        = "get_policy"
            description = "Retrieve policy document by policy ID (e.g., POL-001, POL-002, POL-003)"
            input_schema = {
              type = "object"
              property = [
                {
                  name        = "policyId"
                  type        = "string"
                  description = "Policy ID (e.g., POL-001)"
                  required    = true
                }
              ]
            }
          }
        }
      }
    }
  }

  tags = var.tags

  providers = {
    aws.target_region = aws.primary_region
  }
  depends_on = [
    aws_iam_role_policy.gateway_execution,
    aws_lambda_function.policy_lookup
  ]
}

# =============================================================================
# AGENTCORE RUNTIME MODULE
# =============================================================================

module "agentcore_runtime" {
  source = "../../modules/agentcore-runtime"

  create_agent_runtime      = true
  agent_runtime_name        = replace("${local.name_prefix}agent", "-", "_")
  agent_runtime_role_arn    = aws_iam_role.agent_execution.arn
  container_uri             = var.container_uri
  agent_runtime_description = "Policy Assistant - Direct Gateway→Lambda (No MCP) - v1.0.30"
  protocol_configuration    = "HTTP"

  agent_runtime_environment_variables = {
    BROWSER_ID             = module.agentcore_tools.browser_id
    CODE_INTERPRETER_ID    = module.agentcore_tools.code_interpreter_id
    MEMORY_ID              = module.agentcore_memory.memory_id
    AWS_REGION             = var.aws_region
    GATEWAY_ID             = module.agentcore_gateway.gateway_id
    GATEWAY_URL            = module.agentcore_gateway.gateway_endpoint
    WORKLOAD_IDENTITY_NAME = module.agentcore_identity.workload_identity_name
    # API_KEY_PROVIDER_ARN   = module.agentcore_identity.api_key_provider.credential_provider_arn  # Disabled
    GUARDRAIL_ID           = aws_bedrock_guardrail.example.guardrail_id
    GUARDRAIL_VERSION      = aws_bedrock_guardrail_version.example.version
  }
  # # VPC Network Configuration (optional)
  network_configuration = var.vpc_name != null ? {
    network_mode = "VPC"
    vpc_configuration = {
      subnet_ids         = data.aws_subnets.existing[0].ids
      security_group_ids = [aws_security_group.agentcore[0].id]
    }
  } : null

  create_agent_runtime_endpoint      = true
  agent_runtime_endpoint_name        = replace("${local.name_prefix}_endpoint", "-", "_")
  agent_runtime_endpoint_description = "Weather agent endpoint"

  tags = var.tags

  providers = {
    aws.target_region = aws.primary_region
  }

}

# =============================================================================
# AGENTCORE OBSERVABILITY MODULES
# =============================================================================


# =============================================================================
# CLOUDWATCH LOG GROUPS FOR OBSERVABILITY
# =============================================================================

resource "aws_cloudwatch_log_group" "code_interpreter_usage" {
  provider          = aws.primary_region
  name              = "/aws/bedrock-agentcore/${local.name_prefix}code-interpreter-usage"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

resource "aws_cloudwatch_log_group" "runtime_usage" {
  provider          = aws.primary_region
  name              = "/aws/bedrock-agentcore/${local.name_prefix}runtime-usage"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

resource "aws_cloudwatch_log_group" "browser_usage" {
  provider          = aws.primary_region
  name              = "/aws/bedrock-agentcore/${local.name_prefix}browser-usage"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

resource "aws_cloudwatch_log_group" "memory_usage" {
  provider          = aws.primary_region
  name              = "/aws/bedrock-agentcore/${local.name_prefix}memory-usage"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

resource "aws_cloudwatch_log_group" "gateway_usage" {
  provider          = aws.primary_region
  name              = "/aws/bedrock-agentcore/${local.name_prefix}gateway-usage"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

# =============================================================================
# VPC FLOW LOGS - CLOUDWATCH DESTINATION
# =============================================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.vpc_name != null ? 1 : 0
  provider          = aws.primary_region
  name              = "/aws/vpc/flow-logs/${local.name_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.agentcore.arn
}

resource "aws_iam_role" "vpc_flow_logs" {
  count    = var.vpc_name != null ? 1 : 0
  provider = aws.primary_region
  name     = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count    = var.vpc_name != null ? 1 : 0
  provider = aws.primary_region
  name     = "${local.name_prefix}-vpc-flow-logs-policy"
  role     = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.vpc_flow_logs[0].arn,
          "${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"
        ]
      }
    ]
  })
}

resource "aws_flow_log" "agentcore_vpc" {
  count                    = var.vpc_name != null ? 1 : 0
  provider                 = aws.primary_region
  iam_role_arn             = aws_iam_role.vpc_flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  log_destination_type     = "cloud-watch-logs"
  traffic_type             = "ALL"
  vpc_id                   = data.aws_vpc.existing[0].id
  max_aggregation_interval = 60

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs
  ]
}

# =============================================================================
# AGENTCORE OBSERVABILITY MODULES
# =============================================================================

module "runtime_observability" {
  source = "../../modules/agentcore-observability"

  resource_name = module.agentcore_runtime.agent_runtime_id

  xray_sampling_rule = {
    rule_name    = "${local.name_prefix}runtime"
    service_name = module.agentcore_runtime.agent_runtime_id
    priority     = 8100
    fixed_rate   = 0.1
  }

  log_deliveries = {
    usage = {
      resource_arn             = module.agentcore_runtime.agent_runtime_arn
      log_type                 = "USAGE_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.runtime_usage.arn
    }
  }

  name_prefix = "${local.name_prefix}rt-"

  providers = {
    aws.target_region = aws.primary_region
  }
}

module "memory_observability" {
  source = "../../modules/agentcore-observability"

  resource_name = module.agentcore_memory.memory_id

  xray_sampling_rule = {
    rule_name    = "${local.name_prefix}memory"
    service_name = module.agentcore_memory.memory_id
    priority     = 8200
    fixed_rate   = 0.1
  }

  log_deliveries = {
    app_logs = {
      resource_arn             = module.agentcore_memory.memory_arn
      log_type                 = "APPLICATION_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.memory_usage.arn
    }
  }

  name_prefix = "${local.name_prefix}mem-"

  providers = {
    aws.target_region = aws.primary_region
  }
}

module "browser_observability" {
  source = "../../modules/agentcore-observability"

  resource_name = module.agentcore_tools.browser_id

  xray_sampling_rule = {
    rule_name    = "${local.name_prefix}browser"
    service_name = module.agentcore_tools.browser_id
    priority     = 8300
    fixed_rate   = 0.1
  }

  log_deliveries = {
    usage = {
      resource_arn             = module.agentcore_tools.browser_arn
      log_type                 = "USAGE_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.browser_usage.arn
    }
  }

  name_prefix = "${local.name_prefix}br-"

  providers = {
    aws.target_region = aws.primary_region
  }
}

module "code_interpreter_observability" {
  source = "../../modules/agentcore-observability"

  resource_name = module.agentcore_tools.code_interpreter_id

  xray_sampling_rule = {
    rule_name    = "${local.name_prefix}code-interp"
    service_name = module.agentcore_tools.code_interpreter_id
    priority     = 8000
    fixed_rate   = 0.1
  }

  log_deliveries = {
    usage = {
      resource_arn             = module.agentcore_tools.code_interpreter_arn
      log_type                 = "USAGE_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.code_interpreter_usage.arn
    }
  }

  name_prefix = "${local.name_prefix}ci-"

  providers = {
    aws.target_region = aws.primary_region
  }
}

module "gateway_observability" {
  source = "../../modules/agentcore-observability"

  resource_name = module.agentcore_gateway.gateway_id

  xray_sampling_rule = {
    rule_name    = "${local.name_prefix}gateway"
    service_name = module.agentcore_gateway.gateway_id
    priority     = 8400
    fixed_rate   = 0.1
  }

  log_deliveries = {
    app_logs = {
      resource_arn             = module.agentcore_gateway.gateway_arn
      log_type                 = "APPLICATION_LOGS"
      destination_type         = "CWL"
      destination_resource_arn = aws_cloudwatch_log_group.gateway_usage.arn
    }
  }

  name_prefix = "${local.name_prefix}gw-"

  providers = {
    aws.target_region = aws.primary_region
  }
}
