variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "bastion_iam_role_arn" {
  description = "Bastion IAM role ARN"
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
