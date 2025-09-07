terraform {
  cloud {
    organization = "my-aws-org" # Replace with your organization name

    workspaces {
      name = "my-aws-org-prod" # Replace with your workspace name
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Define variables specific to the prod environment
variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true # Mark as sensitive
  default     = ""   # Provide a default or leave it to be picked up from env
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true # Mark as sensitive
  default     = ""   # Provide a default or leave it to be picked up from env
}