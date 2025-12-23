variable "vpc_id" {
  description = "VPC ID"
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

variable "ecs_api_sg_id" {
  description = "ECS API Security Group ID"
  type        = string
}

variable "ecs_web_sg_id" {
  description = "ECS WEB Security Group ID"
  type        = string
}

variable "bastion_sg_id" {
  description = "Bastion Security Group ID"
  type        = string
}
