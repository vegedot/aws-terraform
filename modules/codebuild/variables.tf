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

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "app_name" {
  description = "Application name (e.g., api, web)"
  type        = string
}

variable "source_bucket_name" {
  description = "S3 bucket name for source code"
  type        = string
}

variable "source_bucket_arn" {
  description = "S3 bucket ARN for source code"
  type        = string
}

variable "source_object_key" {
  description = "S3 object key for source code zip (e.g., api/source.zip)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for CodeBuild (optional - omit to run outside VPC for cost savings)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for CodeBuild (private subnets recommended, required if vpc_id is set)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for CodeBuild (required if vpc_id is set)"
  type        = list(string)
  default     = []
}

variable "compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
}

variable "buildspec_content" {
  description = "Inline buildspec content (optional, otherwise use buildspec.yml in source)"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Additional environment variables for CodeBuild"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 7
}
