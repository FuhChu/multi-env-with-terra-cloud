terraform {
  cloud {
    organization = "my-aws-org" # Replace with your organization name

    workspaces {
      name = "my-aws-org-dev" # Replace with your workspace name
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

# Define variables specific to the dev environment
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

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "desired_count" {
  description = "The desired number of tasks for the ECS service"
  type        = number
}

variable "instance_class" {
  description = "The instance type for the RDS instance"
  type        = string
}

# Call the VPC module
module "vpc" {
  source = "../../modules/vpc" # Adjust path as needed

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  aws_region          = var.aws_region
  environment         = var.environment
}

# Call the ECS Service module
module "ecs_service" {
  source = "../../modules/ecs_service" # Adjust path as needed

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = var.aws_region
  environment        = var.environment
  desired_count      = var.desired_count
}

# Call the RDS module
module "rds" {
  source = "../../modules/rds" # Adjust path as needed

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_username         = var.db_username
  db_password         = var.db_password
  instance_class      = var.instance_class
  environment         = var.environment
}

output "dev_alb_dns_name" {
  description = "The ALB DNS name for the dev environment"
  value       = module.ecs_service.alb_dns_name
}