# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

output "log_delivery_sources" {
  description = "Map of log delivery source names"
  value       = { for k, v in aws_cloudwatch_log_delivery_source.this : k => v.name }
}

output "log_delivery_destinations" {
  description = "Map of log delivery destination ARNs"
  value       = { for k, v in aws_cloudwatch_log_delivery_destination.this : k => v.arn }
}

output "log_deliveries" {
  description = "Map of log delivery IDs"
  value       = { for k, v in aws_cloudwatch_log_delivery.this : k => v.id }
}
