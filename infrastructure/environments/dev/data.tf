# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

# data "aws_ssm_parameter" "core_tags" {
#   provider = aws.primary_region
#   name     = "/aft/account-request/custom-fields/core_tags"
# }

data "aws_caller_identity" "current" {
  provider = aws.primary_region
}

data "aws_region" "current" {
  provider = aws.primary_region
}

data "aws_vpc" "existing" {
  count    = var.vpc_name != null ? 1 : 0
  provider = aws.primary_region

  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "existing" {
  count    = var.vpc_name != null ? 1 : 0
  provider = aws.primary_region

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing[0].id]
  }

  filter {
    name   = "tag:Name"
    values = var.subnet_name_patterns
  }
}
