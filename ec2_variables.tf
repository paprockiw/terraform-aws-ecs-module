# EC2 Vars
variable "ec2_ami_id" {
  default     = "ami-0ec3e36ea5ad3df41"
  type        = string
  description = "ECS-optimized AMI ID"
}

variable "ec2_instance_type" {
  default     = "c1.medium"
  type        = string
  description = "Instance type for ECS nodes"
}


variable "ec2_instance_profile_name" {
  default     = ""
  description = "Name of instance profile for EC2 instances."
  type        = string
}

variable "asg_desired_capacity" {
  default     = 1
  type        = number
  description = "Number of EC2 instances to run as ECS nodes."
}

variable "asg_min_size" {
  default     = 1
  type        = number
  description = "Min count of EC2 instances to run as ECS nodes."
}

variable "asg_max_size" {
  default     = 1
  type        = number
  description = "Max count of EC2 instances to run as ECS nodes."
