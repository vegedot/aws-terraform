variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_type" {
  description = "Type of ALB to create (api or web)"
  type        = string
  validation {
    condition     = contains(["api", "web"], var.alb_type)
    error_message = "alb_type must be either 'api' or 'web'."
  }
}

variable "backend_port" {
  description = "Backend port for target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}
