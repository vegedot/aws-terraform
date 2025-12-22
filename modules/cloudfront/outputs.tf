output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = module.cloudfront.cloudfront_distribution_arn
}
