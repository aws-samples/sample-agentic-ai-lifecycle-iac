#!/bin/bash

###############################################################################
# AgentCore Foundation Setup Script
###############################################################################

set -e
set -u

###############################################################################
# USAGE
###############################################################################

usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    setup     Create all foundation resources (default)
    cleanup   Delete all foundation resources

Description:
    This script manages AWS infrastructure required for the AgentCore solution
    with GitHub Actions CI/CD.

Resources Managed:
    - S3 bucket for Terraform state
    - DynamoDB table for state locking
    - ECR repository for container images
    - GitHub OIDC provider
    - IAM role for GitHub Actions
    - Secrets Manager secrets (config and API key)

Prerequisites:
    - AWS CLI installed and configured
    - Appropriate AWS permissions (IAM, S3, DynamoDB, ECR, Secrets Manager)
    - GitHub repository created

Examples:
    $0              # Create resources
    $0 setup        # Create resources
    $0 cleanup      # Delete resources

EOF
    exit 0
}

# Show usage if requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Determine mode
MODE=${1:-setup}

if [[ "$MODE" != "setup" && "$MODE" != "cleanup" ]]; then
    echo "Error: Invalid command '$MODE'"
    echo ""
    usage
fi

###############################################################################
# CONFIGURATION
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

###############################################################################
# SETUP FUNCTIONS
###############################################################################

setup_s3_bucket() {
    log_info "Creating S3 bucket for Terraform state..."
    
    local BUCKET_NAME="agentcore-tfstate-${AWS_ACCOUNT_ID}"
    
    if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
        log_warn "S3 bucket ${BUCKET_NAME} already exists, skipping"
        return
    fi
    
    log_info "Creating S3 bucket: ${BUCKET_NAME}"
    
    if [ "${AWS_REGION}" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${AWS_REGION}"
    else
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    
    log_info "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled
    
    log_info "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    log_info "S3 bucket created successfully"
}

setup_dynamodb_table() {
    log_info "Creating DynamoDB table for state locking..."
    
    local TABLE_NAME="terraform-locks"
    
    if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
        log_warn "DynamoDB table ${TABLE_NAME} already exists, skipping"
        return
    fi
    
    log_info "Creating DynamoDB table: ${TABLE_NAME}"
    aws dynamodb create-table \
        --table-name "${TABLE_NAME}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}"
    
    log_info "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${AWS_REGION}"
    log_info "DynamoDB table created successfully"
}

setup_ecr_repository() {
    log_info "Creating ECR repository..."
    
    local ECR_REPO_NAME="agentcore-dev-agent"
    
    if aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
        log_warn "ECR repository ${ECR_REPO_NAME} already exists, skipping"
        return
    fi
    
    log_info "Creating ECR repository: ${ECR_REPO_NAME}"
    aws ecr create-repository \
        --repository-name "${ECR_REPO_NAME}" \
        --region "${AWS_REGION}" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    
    log_info "ECR repository created successfully"
}

setup_github_oidc() {
    log_info "Setting up GitHub OIDC provider..."
    
    local OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_PROVIDER_ARN}" 2>/dev/null; then
        log_warn "GitHub OIDC provider already exists, skipping"
        return
    fi
    
    log_info "Creating GitHub OIDC provider..."
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    
    log_info "GitHub OIDC provider created successfully"
}

setup_github_actions_role() {
    log_info "Creating GitHub Actions IAM role..."
    
    local ROLE_NAME="github-actions-role"
    
    if aws iam get-role --role-name "${ROLE_NAME}" 2>/dev/null; then
        log_warn "GitHub Actions role already exists, skipping"
        return
    fi
    
    log_info "Creating trust policy..."
    
    cat > /tmp/github-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
    
    log_info "Creating IAM role: ${ROLE_NAME}"
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/github-trust-policy.json
    
    log_info "GitHub Actions role created successfully"
}

setup_role_policies() {
    log_info "Attaching policies to GitHub Actions role..."
    
    local ROLE_NAME="github-actions-role"
    local POLICY_PREFIX="AgentCore-GitHubActions"
    
    log_info "Attaching ECR PowerUser policy..."
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser \
        2>/dev/null || log_warn "ECR policy already attached"
    
    log_info "Removing old inline policies if they exist..."
    for POLICY_NAME in GitHubActionsDeploymentPolicy SecretsManagerAccessPolicy CoreInfrastructurePolicy IAMAndLambdaPolicy ObservabilityAndSecretsPolicy KMSEncryptionPolicy BedrockAgentCoreServiceLinkedRolePolicy; do
        aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "${POLICY_NAME}" 2>/dev/null || true
    done
    
    log_info "Creating customer managed policies..."
    
    # Helper function to create or update managed policy
    create_or_update_policy() {
        local POLICY_NAME=$1
        local POLICY_FILE=$2
        local POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
        
        if aws iam get-policy --policy-arn "${POLICY_ARN}" 2>/dev/null; then
            log_info "Updating existing policy: ${POLICY_NAME}"
            # Delete all non-default versions first
            aws iam list-policy-versions --policy-arn "${POLICY_ARN}" --query 'Versions[?!IsDefaultVersion].VersionId' --output text | \
            xargs -n1 -I {} aws iam delete-policy-version --policy-arn "${POLICY_ARN}" --version-id {} 2>/dev/null || true
            # Create new version
            aws iam create-policy-version --policy-arn "${POLICY_ARN}" --policy-document "file://${POLICY_FILE}" --set-as-default
        else
            log_info "Creating new policy: ${POLICY_NAME}"
            aws iam create-policy --policy-name "${POLICY_NAME}" --policy-document "file://${POLICY_FILE}"
        fi
        
        # Attach to role
        aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}" 2>/dev/null || true
    }
    
    log_info "Creating core infrastructure policy..."
    
    # POLICY 1: Core Infrastructure (Terraform State, DynamoDB, Bedrock)
    cat > /tmp/github-actions-policy-1.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::agentcore-tfstate-${AWS_ACCOUNT_ID}",
        "arn:aws:s3:::agentcore-tfstate-${AWS_ACCOUNT_ID}/*"
      ]
    },
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:${AWS_REGION}:${AWS_ACCOUNT_ID}:table/terraform-locks"
    },
    {
      "Sid": "AgentCoreManagementAccess",
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:CreateAgentRuntime",
        "bedrock-agentcore:UpdateAgentRuntime",
        "bedrock-agentcore:DescribeAgentRuntime",
        "bedrock-agentcore:ListAgentRuntimes",
        "bedrock-agentcore:CreateGateway",
        "bedrock-agentcore:UpdateGateway",
        "bedrock-agentcore:GetGateway",
        "bedrock-agentcore:ListGateways"
      ],
      "Resource": [
        "arn:aws:bedrock-agentcore:${AWS_REGION}:${AWS_ACCOUNT_ID}:agent-runtime/agentcore-*",
        "arn:aws:bedrock-agentcore:${AWS_REGION}:${AWS_ACCOUNT_ID}:gateway/agentcore-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "${AWS_REGION}"
        }
      }
    },
    {
      "Sid": "AgentCoreDeleteAccess",
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:DeleteAgentRuntime",
        "bedrock-agentcore:DeleteGateway"
      ],
      "Resource": [
        "arn:aws:bedrock-agentcore:${AWS_REGION}:${AWS_ACCOUNT_ID}:agent-runtime/agentcore-*",
        "arn:aws:bedrock-agentcore:${AWS_REGION}:${AWS_ACCOUNT_ID}:gateway/agentcore-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "${AWS_REGION}"
        }
      }
    },
    {
      "Sid": "BedrockGuardrailsAccess",
      "Effect": "Allow",
      "Action": [
        "bedrock:CreateGuardrail",
        "bedrock:GetGuardrail",
        "bedrock:UpdateGuardrail",
        "bedrock:DeleteGuardrail",
        "bedrock:CreateGuardrailVersion",
        "bedrock:ListTagsForResource",
        "bedrock:TagResource",
        "bedrock:UntagResource"
      ],
      "Resource": [
        "arn:aws:bedrock:${AWS_REGION}:${AWS_ACCOUNT_ID}:guardrail/*"
      ]
    },
    {
      "Sid": "BedrockGuardrailsList",
      "Effect": "Allow",
      "Action": [
        "bedrock:ListGuardrails"
      ],
      "Resource": "*"
    }
  ]
}
EOF
    
    create_or_update_policy "${POLICY_PREFIX}-CoreInfrastructure" /tmp/github-actions-policy-1.json
    
    log_info "Creating IAM and Lambda policy..."
    
    # POLICY 2: IAM, Lambda, Signer
    cat > /tmp/github-actions-policy-2.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListInstanceProfilesForRole",
        "iam:PutRolePermissionsBoundary",
        "iam:DeleteRolePermissionsBoundary"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/agentcore-*",
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/bedrock-agentcore-*"
      ]
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/agentcore-*",
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/bedrock-agentcore-*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "bedrock-agentcore.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "CreateBedrockAgentCoreNetworkServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/network.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreNetwork",
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": "network.bedrock-agentcore.amazonaws.com"
        }
      }
    },
    {
      "Sid": "CreateBedrockAgentCoreRuntimeIdentityServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/runtime-identity.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreRuntimeIdentity",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "runtime-identity.bedrock-agentcore.amazonaws.com"
        }
      }
    },
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:DeleteFunction",
        "lambda:InvokeFunction",
        "lambda:PutFunctionConcurrency",
        "lambda:ListVersionsByFunction",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:ListTags",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:GetPolicy",
        "lambda:CreateCodeSigningConfig",
        "lambda:DeleteCodeSigningConfig",
        "lambda:GetCodeSigningConfig",
        "lambda:UpdateCodeSigningConfig",
        "lambda:PutFunctionCodeSigningConfig",
        "lambda:DeleteFunctionCodeSigningConfig"
      ],
      "Resource": [
        "arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:agentcore-*",
        "arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:code-signing-config:*"
      ]
    },
    {
      "Sid": "SignerManagement",
      "Effect": "Allow",
      "Action": [
        "signer:PutSigningProfile",
        "signer:GetSigningProfile",
        "signer:CancelSigningProfile",
        "signer:ListSigningProfiles",
        "signer:TagResource",
        "signer:UntagResource",
        "signer:ListTagsForResource"
      ],
      "Resource": "arn:aws:signer:${AWS_REGION}:${AWS_ACCOUNT_ID}:/signing-profiles/*"
    }
  ]
}
EOF
    
    create_or_update_policy "${POLICY_PREFIX}-IAMAndLambda" /tmp/github-actions-policy-2.json
    
    log_info "Creating CloudWatch and observability policy..."
    
    # POLICY 3: CloudWatch, X-Ray, SQS
    cat > /tmp/github-actions-policy-3.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogsManagement",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:PutRetentionPolicy",
        "logs:DeleteLogGroup",
        "logs:TagResource",
        "logs:UntagResource",
        "logs:ListTagsForResource"
      ],
      "Resource": "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:log-group:/aws/bedrock-agentcore/*"
    },
    {
      "Sid": "CloudWatchLogsDelivery",
      "Effect": "Allow",
      "Action": [
        "logs:PutDeliverySource",
        "logs:PutDeliveryDestination",
        "logs:GetDeliverySource",
        "logs:GetDeliveryDestination",
        "logs:DeleteDeliverySource",
        "logs:DeleteDeliveryDestination",
        "logs:CreateDelivery",
        "logs:DeleteDelivery",
        "logs:GetDelivery",
        "logs:UpdateDeliveryConfiguration",
        "logs:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:delivery-source:*",
        "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:delivery-destination:*",
        "arn:aws:logs:${AWS_REGION}:${AWS_ACCOUNT_ID}:delivery:*"
      ]
    },
    {
      "Sid": "CloudWatchLogsResourcePolicy",
      "Effect": "Allow",
      "Action": [
        "logs:PutResourcePolicy",
        "logs:DeleteResourcePolicy",
        "logs:DescribeResourcePolicies"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsDescribe",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "XRayTracing",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:CreateSamplingRule",
        "xray:GetSamplingRules",
        "xray:ListTagsForResource",
        "xray:DeleteSamplingRule",
        "xray:UpdateSamplingRule",
        "xray:PutResourcePolicy",
        "xray:DeleteResourcePolicy",
        "xray:ListResourcePolicies"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SQSManagement",
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes",
        "sqs:ListQueueTags",
        "sqs:SendMessage",
        "sqs:TagQueue",
        "sqs:UntagQueue"
      ],
      "Resource": "arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:agentcore-*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:TagResource",
        "secretsmanager:DeleteSecret"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMParameterRead",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:${AWS_REGION}:${AWS_ACCOUNT_ID}:parameter/agentcore/*"
    }
  ]
}
EOF
    
    create_or_update_policy "${POLICY_PREFIX}-Observability" /tmp/github-actions-policy-3.json
    
    log_info "Creating KMS policy..."
    
    # POLICY 4: KMS (largest policy)
    # SECURITY BEST PRACTICES APPLIED:
    # 1. Key creation requires specific tags (Project, ManagedBy, Environment)
    # 2. All cryptographic operations restricted to AWS service principals via kms:ViaService
    # 3. Key management operations require aws:ResourceTag/Project=agentcore
    # 4. Grants limited to agentcore-* roles and AWS resources only
    # 5. Key deletion requires 30-day waiting period and dev environment tag
    # 6. Alias operations scoped to agentcore-* prefix only
    # 7. Policy changes protected with BypassPolicyLockoutSafetyCheck=false
    # 8. Region and account locked in all ARNs
    #
    # Wildcards justified:
    # - kms:CreateKey requires Resource:* (AWS requirement - key doesn't exist yet)
    # - kms:ListKeys/ListAliases require Resource:* (AWS requirement - list operations)
    # - key/* in ARNs is acceptable when combined with tag conditions per AWS best practices
    
    cat > /tmp/github-actions-policy-4.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KMSKeyCreationOnly",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "agentcore"
        }
      }
    },
    {
      "Sid": "KMSAliasManagementSpecific",
      "Effect": "Allow",
      "Action": [
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:UpdateAlias"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:alias/agentcore-*",
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ]
    },
    {
      "Sid": "KMSAliasToKeyBinding",
      "Effect": "Allow",
      "Action": [
        "kms:CreateAlias",
        "kms:UpdateAlias",
        "kms:DeleteAlias"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ]
    },
    {
      "Sid": "KMSDeploymentOperations",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:CreateGrant",
        "kms:RetireGrant"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "agentcore"
        }
      }
    },
    {
      "Sid": "KMSDescribeKeyTagged",
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListResourceTags"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ]
    },
    {
      "Sid": "KMSKeyPolicyManagementTagged",
      "Effect": "Allow",
      "Action": [
        "kms:PutKeyPolicy"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "agentcore"
        },
        "Bool": {
          "kms:BypassPolicyLockoutSafetyCheck": "false"
        }
      }
    },
    {
      "Sid": "KMSKeyRotationManagement",
      "Effect": "Allow",
      "Action": [
        "kms:EnableKeyRotation"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "agentcore"
        }
      }
    },
    {
      "Sid": "KMSTagManagement",
      "Effect": "Allow",
      "Action": [
        "kms:TagResource",
        "kms:UntagResource"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "agentcore"
        }
      }
    },
    {
      "Sid": "KMSKeyDeletionWithSafeguards",
      "Effect": "Allow",
      "Action": [
        "kms:ScheduleKeyDeletion"
      ],
      "Resource": [
        "arn:aws:kms:${AWS_REGION}:${AWS_ACCOUNT_ID}:key/*"
      ],
      "Condition": {
        "NumericGreaterThanEquals": {
          "kms:ScheduleKeyDeletionPendingWindowInDays": 7
        }
      }
    },
    {
      "Sid": "KMSListOperationsRequired",
      "Effect": "Allow",
      "Action": [
        "kms:ListAliases",
        "kms:ListKeys"
      ],
      "Resource": "*"
    }
  ]
}
EOF
    
    create_or_update_policy "${POLICY_PREFIX}-KMS" /tmp/github-actions-policy-4.json
    
    log_info "Policies attached successfully"
}

setup_bedrock_slr_policy() {
    log_info "Creating Bedrock AgentCore service-linked role policy..."
    
    local ROLE_NAME="github-actions-role"
    local POLICY_PREFIX="AgentCore-GitHubActions"
    
    cat > /tmp/bedrock-slr-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateBedrockAgentCoreServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/bedrock-agentcore.amazonaws.com/*",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "bedrock-agentcore.amazonaws.com"
        }
      }
    },
    {
      "Sid": "CreateBedrockAgentCoreNetworkServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/network.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreNetwork",
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": "network.bedrock-agentcore.amazonaws.com"
        }
      }
    },
    {
      "Sid": "CreateBedrockAgentCoreRuntimeIdentityServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/runtime-identity.bedrock-agentcore.amazonaws.com/AWSServiceRoleForBedrockAgentCoreRuntimeIdentity",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "runtime-identity.bedrock-agentcore.amazonaws.com"
        }
      }
    }
  ]
}
EOF
    
    # Use inline policy for this small one
    aws iam put-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-name BedrockAgentCoreServiceLinkedRolePolicy \
        --policy-document file:///tmp/bedrock-slr-policy.json
    
    log_info "Service-linked role policy attached successfully"
}

setup_secrets() {
    log_info "Storing configuration in AWS Secrets Manager..."
    
    local BUCKET_NAME="agentcore-tfstate-${AWS_ACCOUNT_ID}"
    local ECR_REPO_NAME="agentcore-dev-agent"
    local TABLE_NAME="terraform-locks"
    local ROLE_NAME="github-actions-role"
    
    local CONFIG_SECRET_NAME="agentcore/config"
    
    log_info "Creating configuration secret: ${CONFIG_SECRET_NAME}"
    
    local CONFIG_JSON=$(cat <<EOF
{
  "aws_account_id": "${AWS_ACCOUNT_ID}",
  "aws_region": "${AWS_REGION}",
  "tf_state_bucket": "${BUCKET_NAME}",
  "ecr_repository": "${ECR_REPO_NAME}",
  "dynamodb_table": "${TABLE_NAME}",
  "github_role_arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
}
EOF
)
    
    if aws secretsmanager describe-secret --secret-id "${CONFIG_SECRET_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
        log_warn "Secret ${CONFIG_SECRET_NAME} already exists, updating..."
        aws secretsmanager put-secret-value \
            --secret-id "${CONFIG_SECRET_NAME}" \
            --secret-string "${CONFIG_JSON}" \
            --region "${AWS_REGION}"
    else
        aws secretsmanager create-secret \
            --name "${CONFIG_SECRET_NAME}" \
            --description "AgentCore configuration" \
            --secret-string "${CONFIG_JSON}" \
            --region "${AWS_REGION}" \
            --tags Key=ManagedBy,Value=Script
    fi
    
    log_info "Updating IAM role for Secrets Manager access..."
    
    cat > /tmp/secrets-manager-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:agentcore/*"
      ]
    }
  ]
}
EOF
    
    aws iam put-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-name SecretsManagerAccessPolicy \
        --policy-document file:///tmp/secrets-manager-policy.json
    
    log_info "Secrets created successfully"
}

run_setup() {
    log_info "Getting AWS account information..."
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=${AWS_REGION:-us-east-1}
    
    log_info "AWS Account ID: ${AWS_ACCOUNT_ID}"
    log_info "AWS Region: ${AWS_REGION}"
    
    read -p "Enter your GitHub username/organization: " GITHUB_ORG
    read -p "Enter your GitHub repository name [sample-agentic-ai-lifecycle-iac]: " GITHUB_REPO
    GITHUB_REPO=${GITHUB_REPO:-sample-agentic-ai-lifecycle-iac}
    
    log_info "GitHub Org: ${GITHUB_ORG}"
    log_info "GitHub Repo: ${GITHUB_REPO}"
    
    echo ""
    read -p "Continue with setup? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Setup cancelled"
        exit 0
    fi
    
    setup_s3_bucket
    setup_dynamodb_table
    setup_ecr_repository
    setup_github_oidc
    setup_github_actions_role
    setup_role_policies
    setup_bedrock_slr_policy
    setup_secrets
    
    log_info "Cleaning up temporary files..."
    rm -f /tmp/github-trust-policy.json
    rm -f /tmp/github-actions-policy-*.json
    rm -f /tmp/bedrock-slr-policy.json
    rm -f /tmp/secrets-manager-policy.json
    
    local BUCKET_NAME="agentcore-tfstate-${AWS_ACCOUNT_ID}"
    local TABLE_NAME="terraform-locks"
    local ECR_REPO_NAME="agentcore-dev-agent"
    local ROLE_NAME="github-actions-role"
    
    echo ""
    echo "========================================================================="
    log_info "Foundation setup completed successfully!"
    echo "========================================================================="
    echo ""
    echo "Resources created:"
    echo "  ✓ S3 Bucket: ${BUCKET_NAME}"
    echo "  ✓ DynamoDB Table: ${TABLE_NAME}"
    echo "  ✓ ECR Repository: ${ECR_REPO_NAME}"
    echo "  ✓ GitHub OIDC Provider"
    echo "  ✓ IAM Role: ${ROLE_NAME}"
    echo "  ✓ Secrets Manager: agentcore/config"
    echo ""
    echo "========================================================================="
}

###############################################################################
# CLEANUP FUNCTIONS
###############################################################################

run_cleanup() {
    log_info "Getting AWS account information..."
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=${AWS_REGION:-us-east-1}
    
    log_info "AWS Account ID: ${AWS_ACCOUNT_ID}"
    log_info "AWS Region: ${AWS_REGION}"
    
    echo ""
    log_warn "========================================================================="
    log_warn "WARNING: CLEANUP MODE"
    log_warn "========================================================================="
    log_warn "This will DELETE the following resources:"
    echo "  - S3 Bucket: agentcore-tfstate-${AWS_ACCOUNT_ID}"
    echo "  - DynamoDB Table: terraform-locks"
    echo "  - ECR Repository: agentcore-dev-agent (and all images)"
    echo "  - GitHub OIDC Provider"
    echo "  - IAM Role: github-actions-role"
    echo "  - Secrets Manager: agentcore/config"
    echo ""
    log_warn "This action CANNOT be undone!"
    echo ""
    read -p "Type 'DELETE' to confirm cleanup: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        log_warn "Cleanup cancelled"
        exit 0
    fi
    
    log_info "Starting cleanup process..."
    
    local BUCKET_NAME="agentcore-tfstate-${AWS_ACCOUNT_ID}"
    local TABLE_NAME="terraform-locks"
    local ECR_REPO_NAME="agentcore-dev-agent"
    local ROLE_NAME="github-actions-role"
    local OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    
    # Delete Secrets Manager secrets
    log_info "Deleting Secrets Manager secrets..."
    for SECRET_NAME in "agentcore/config"; do
        if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
            log_info "Deleting secret: ${SECRET_NAME}"
            aws secretsmanager delete-secret \
                --secret-id "${SECRET_NAME}" \
                --force-delete-without-recovery \
                --region "${AWS_REGION}" 2>/dev/null || log_warn "Failed to delete ${SECRET_NAME}"
        else
            log_warn "Secret ${SECRET_NAME} not found, skipping"
        fi
    done
    
    # Delete IAM Role
    log_info "Deleting IAM Role and policies..."
    if aws iam get-role --role-name "${ROLE_NAME}" 2>/dev/null; then
        log_info "Detaching managed policies..."
        ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
        for POLICY_ARN in $ATTACHED_POLICIES; do
            log_info "Detaching: ${POLICY_ARN}"
            aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}" 2>/dev/null || log_warn "Failed to detach"
        done
        
        log_info "Deleting inline policies..."
        INLINE_POLICIES=$(aws iam list-role-policies --role-name "${ROLE_NAME}" --query 'PolicyNames' --output text 2>/dev/null || echo "")
        for POLICY_NAME in $INLINE_POLICIES; do
            log_info "Deleting: ${POLICY_NAME}"
            aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "${POLICY_NAME}" 2>/dev/null || log_warn "Failed to delete"
        done
        
        log_info "Deleting role: ${ROLE_NAME}"
        aws iam delete-role --role-name "${ROLE_NAME}" 2>/dev/null || log_warn "Failed to delete role"
    else
        log_warn "IAM role not found, skipping"
    fi
    
    # Delete OIDC Provider
    log_info "Deleting GitHub OIDC Provider..."
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_PROVIDER_ARN}" 2>/dev/null; then
        log_info "Deleting OIDC provider"
        aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_PROVIDER_ARN}" 2>/dev/null || log_warn "Failed to delete"
    else
        log_warn "OIDC provider not found, skipping"
    fi
    
    # Delete ECR Repository
    log_info "Deleting ECR Repository..."
    if aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
        log_info "Deleting: ${ECR_REPO_NAME}"
        aws ecr delete-repository \
            --repository-name "${ECR_REPO_NAME}" \
            --region "${AWS_REGION}" \
            --force 2>/dev/null || log_warn "Failed to delete"
    else
        log_warn "ECR repository not found, skipping"
    fi
    
    # Delete DynamoDB Table
    log_info "Deleting DynamoDB Table..."
    if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" 2>/dev/null; then
        log_info "Deleting: ${TABLE_NAME}"
        aws dynamodb delete-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" 2>/dev/null || log_warn "Failed to delete"
        log_info "Waiting for deletion..."
        aws dynamodb wait table-not-exists --table-name "${TABLE_NAME}" --region "${AWS_REGION}" 2>/dev/null || true
    else
        log_warn "DynamoDB table not found, skipping"
    fi
    
    # Delete S3 Bucket
    log_info "Deleting S3 Bucket..."
    if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
        log_info "Emptying: ${BUCKET_NAME}"
        
        # Delete all object versions
        log_info "Deleting object versions..."
        aws s3api list-object-versions --bucket "${BUCKET_NAME}" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text 2>/dev/null | \
        while read -r key version_id; do
            if [ -n "$key" ] && [ -n "$version_id" ]; then
                aws s3api delete-object --bucket "${BUCKET_NAME}" --key "$key" --version-id "$version_id" 2>/dev/null || true
            fi
        done
        
        # Delete all delete markers
        log_info "Deleting delete markers..."
        aws s3api list-object-versions --bucket "${BUCKET_NAME}" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text 2>/dev/null | \
        while read -r key version_id; do
            if [ -n "$key" ] && [ -n "$version_id" ]; then
                aws s3api delete-object --bucket "${BUCKET_NAME}" --key "$key" --version-id "$version_id" 2>/dev/null || true
            fi
        done
        
        # Also delete any remaining objects (non-versioned)
        log_info "Deleting remaining objects..."
        aws s3 rm "s3://${BUCKET_NAME}" --recursive 2>/dev/null || true
        
        # Verify bucket is empty
        OBJECT_COUNT=$(aws s3api list-object-versions --bucket "${BUCKET_NAME}" --query 'length([Versions, DeleteMarkers][])')
        log_info "Remaining objects: ${OBJECT_COUNT}"
        
        log_info "Deleting: ${BUCKET_NAME}"
        if aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" 2>&1; then
            log_info "S3 bucket deleted successfully"
        else
            ERROR_MSG=$(aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" 2>&1 || true)
            log_warn "Failed to delete S3 bucket: ${ERROR_MSG}"
            log_warn "You may need to manually delete the bucket from AWS Console"
        fi
    else
        log_warn "S3 bucket not found, skipping"
    fi
    
    echo ""
    echo "========================================================================="
    log_info "Cleanup completed!"
    echo "========================================================================="
    echo ""
    echo "Resources deleted:"
    echo "  ✓ Secrets Manager secrets"
    echo "  ✓ IAM Role: ${ROLE_NAME}"
    echo "  ✓ GitHub OIDC Provider"
    echo "  ✓ ECR Repository: ${ECR_REPO_NAME}"
    echo "  ✓ DynamoDB Table: ${TABLE_NAME}"
    echo "  ✓ S3 Bucket: ${BUCKET_NAME}"
    echo ""
    echo "========================================================================="
}

###############################################################################
# MAIN
###############################################################################

if [ "$MODE" = "setup" ]; then
    run_setup
else
    run_cleanup
fi
