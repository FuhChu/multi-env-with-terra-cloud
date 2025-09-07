variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "hello-world-app"
}

variable "container_port" {
  description = "The port the application container listens on"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "The desired number of tasks for the ECS service"
  type        = number
  default     = 1
}

variable "fargate_cpu" {
  description = "The Fargate CPU size"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "The Fargate memory size"
  type        = number
  default     = 512
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}