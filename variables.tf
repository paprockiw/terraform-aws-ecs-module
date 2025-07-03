# Common Vars
variable "account_num" {
  type        = number
  description = "AWS account number"
}

variable "platform" {
  type        = string
  description = "Name of the platform"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
}

variable "region" {
  type        = string
  description = "AWS region"
}


# ECS Cluster vars
variable "aws_vpc" {
  description = "The VPC for this ECS cluster."
  type        = string
}

variable "service_launch_type" {
  description = "The type of service: Fargate/EC2."
  type        = string
  default     = "FARGATE"
}

variable "ecs_subnets" {
  description = "Public subnets for the ALB."
  type        = list(string)
}


# log vars
variable "log_retention_days" {
  default     = 7
  description = "Number of days to keep logs."
  type        = number
}
