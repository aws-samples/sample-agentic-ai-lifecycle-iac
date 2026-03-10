project_name = "agentcore-test"
environment  = "dev"
aws_region   = "us-east-1"

enable_browser           = true
enable_code_interpreter  = true
enable_api_key_provider  = false  # Disabled - not deploying identity
enable_oauth2_provider   = false
enable_workload_identity = false  # Disabled - not deploying identity
enable_gateway           = false  # Disabled - not deploying gateway
enable_memory            = true
enable_memory_strategy   = true
enable_runtime           = true
enable_runtime_endpoint  = true

# Change this to the right URL - using dev-latest tag for dev environment
container_uri = "619071314915.dkr.ecr.us-east-1.amazonaws.com/agentcore-dev-agent:dev-latest"

create_kms_key      = true # Enabled after adding KMS permissions to boundary
kms_deletion_window = 7

# Observability Configuration
enable_genai_observability = true
enable_runtime_alarms      = true
enable_memory_alarms       = true
enable_gateway_alarms      = false  # Disabled - gateway not deployed
enable_identity_alarms     = false  # Disabled - identity not deployed
enable_xray_tracing        = true

# Alarm thresholds
error_rate_threshold          = 5
error_rate_period             = 300
error_rate_evaluation_periods = 2
latency_threshold             = 5000
latency_period                = 300
latency_evaluation_periods    = 2

# X-Ray configuration
xray_sampling_priority = 9000
xray_reservoir_size    = 1
xray_fixed_rate        = 0.1

api_key = ""  # Set via TF_VAR_api_key environment variable or AWS Secrets Manager

# Guardrail configuration (disabled - no guardrails available)
# guardrail_id      = "ap8dfaek453j"
# guardrail_version = "1"

#vpc_name             = "policy-001-us-east-1" # Replace with your actual VPC name
#subnet_name_patterns = ["*core_network-us-east-1b*"]

# Memory strategy configuration
memory_strategy_type = "SEMANTIC"

tags = {
  Environment = "demo"
}
