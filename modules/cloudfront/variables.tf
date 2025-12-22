variable "s3_bucket_id" {
  description = "S3 bucket ID"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "web_alb_dns_name" {
  description = "WEB ALB DNS name"
  type        = string
}

variable "api_alb_dns_name" {
  description = "API ALB DNS name"
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

variable "web_acl_id" {
  description = "WAF Web ACL ID to associate with CloudFront distribution"
  type        = string
  default     = null
}

variable "web_cache_policy_name" {
  description = "Cache policy name for WEB application path (/app/*). PoC: Managed-CachingDisabled, Production: Managed-CachingOptimized"
  type        = string
  default     = "Managed-CachingDisabled"
}

variable "lambda_edge_viewer_request_arn" {
  description = "Lambda@Edge function ARN for viewer-request event (must be qualified ARN with version)"
  type        = string
  default     = null
}

variable "lambda_edge_viewer_response_arn" {
  description = "Lambda@Edge function ARN for viewer-response event (must be qualified ARN with version)"
  type        = string
  default     = null
}

variable "lambda_edge_origin_request_arn" {
  description = "Lambda@Edge function ARN for origin-request event (must be qualified ARN with version)"
  type        = string
  default     = null
}

variable "lambda_edge_origin_response_arn" {
  description = "Lambda@Edge function ARN for origin-response event (must be qualified ARN with version)"
  type        = string
  default     = null
}
