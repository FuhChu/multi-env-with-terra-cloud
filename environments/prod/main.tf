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

# Call the VPC module to create the Virtual Private Cloud infrastructure
module "vpc" {
  source = "../../modules/vpc" # Path to your VPC module

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  aws_region           = var.aws_region
  environment          = var.environment
}

# Call the ECS Service module to deploy your containerized application
module "ecs_service" {
  source = "../../modules/ecs_service" # Path to your ECS Service module

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = var.aws_region
  environment        = var.environment
  desired_count      = var.desired_count
}

# Call the RDS module to provision your Relational Database Service instance
module "rds" {
  source = "../../modules/rds" # Path to your RDS module

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_username           = var.db_username
  db_password           = var.db_password
  instance_class        = var.instance_class
  environment           = var.environment
  ecs_security_group_id = module.ecs_service.ecs_security_group_id
}

output "prod_alb_dns_name" {
  description = "The ALB DNS name for the prod environment"
  value       = module.ecs_service.alb_dns_name
}