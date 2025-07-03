# ALB vars
variable "enable_alb" {
  default     = false
  description = "Whether to enable an application load balancer (true or false)."
  type        = bool
}

variable "alb_subnets" {
  default     = []
  description = "Subnets to run ALB on (public or private, needs at least 2)."
  type        = list(string)
}

variable "internal_alb" {
  default     = false
  description = "Whether ALB is public or private (true/false)."
  type        = bool
}

variable "alb_tg_port" {
  default     = 443
  description = "Port number for the target group associated with the ALB."
  type        = number
}

variable "alb_tg_protocol" {
  default     = "HTTPS"
  description = "Protocol for target group associated with the ALB."
  type        = string
}

variable "alb_listener_port" {
  default     = 443
  description = "Port number for the listenter associated with the ALB."
  type        = number
}

variable "alb_listener_protocol" {
  default     = "HTTPS"
  description = "Protocol for listener associated with the ALB."
  type        = string
}

variable "alb_ecs_sgs" {
  description = "Security groups for ALB."
  type        = list(string)
}
