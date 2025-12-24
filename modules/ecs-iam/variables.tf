variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., poc, dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "app_name" {
  description = "Application name (e.g., api, web)"
  type        = string
}

variable "enable_dynamodb_access" {
  description = "Enable DynamoDB access for the task role"
  type        = bool
  default     = false
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table (required if enable_dynamodb_access is true)"
  type        = string
  default     = ""
}

variable "enable_aurora_access" {
  description = "Enable Aurora (RDS) access via Secrets Manager for the task role"
  type        = bool
  default     = false
}

variable "enable_xray" {
  description = "Enable AWS X-Ray tracing for the task role"
  type        = bool
  default     = false
}
