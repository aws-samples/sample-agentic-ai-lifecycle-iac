# © 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.
terraform {
  required_version = ">= 1.9.6"

  required_providers {
    aws = {
      # source  = "localterraform.com/SSC/aws"
      source                = "hashicorp/aws"
      version               = ">=5.0.0, <=6.27.0"
      configuration_aliases = [aws.primary_region, aws.secondary_region]
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  alias  = "secondary_region"
  region = "ca-central-1"
}

provider "aws" {
  alias  = "primary_region"
  region = "us-east-1"
}
