output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.cloudfront.id
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "ip_set_arn" {
  description = "WAF IP Set ARN"
  value       = length(aws_wafv2_ip_set.allowed_ips) > 0 ? aws_wafv2_ip_set.allowed_ips[0].arn : null
}
