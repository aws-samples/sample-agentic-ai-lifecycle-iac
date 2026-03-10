# Variables for Complete AgentCore Demo

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "demo"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "container_uri" {
  description = "ECR container URI for the agent"
  type        = string
}

variable "api_key" {
  description = "API key for API key provider"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# VPC CONFIGURATION (OPTIONAL)
# =============================================================================

variable "vpc_name" {
  description = "Name of the VPC for AgentCore deployment (optional, for VPC mode)"
  type        = string
  default     = null
}

variable "subnet_name_patterns" {
  description = "List of subnet name patterns to filter for VPC deployment"
  type        = list(string)
  default     = ["*private*"]
}

# =============================================================================
# GUARDRAIL CONFIGURATION (OPTIONAL)
# =============================================================================

# variable "guardrail_id" {
#   description = "Guardrail ID for the agent (optional)"
#   type        = string
#   default     = "ap8dfaek453j"
# }

# variable "guardrail_version" {
#   description = "Guardrail version"
#   type        = string
#   default     = "1"
# }
