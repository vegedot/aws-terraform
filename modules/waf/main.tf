# WAF IP Set for allowed IP addresses
resource "aws_wafv2_ip_set" "allowed_ips" {
  count = length(var.allowed_ip_addresses) > 0 ? 1 : 0

  name               = "${var.project_name}-${var.environment}-waf-ipset"
  description        = "Allowed IP addresses"
  scope              = "CLOUDFRONT"
  region             = "us-east-1"  # CloudFront WAF must be in us-east-1
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-waf-ipset"
    }
  )
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${var.project_name}-${var.environment}-waf-cloudfront"
  description = length(var.allowed_ip_addresses) > 0 ? "WAF for CloudFront with IP restrictions" : "WAF for CloudFront without IP restrictions"
  scope       = "CLOUDFRONT"
  region      = "us-east-1"  # CloudFront WAF must be in us-east-1

  # IP制限あり: ブロック、IP制限なし: 全許可
  default_action {
    dynamic "allow" {
      for_each = length(var.allowed_ip_addresses) == 0 ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = length(var.allowed_ip_addresses) > 0 ? [1] : []
      content {}
    }
  }

  # IP制限ありの場合のみ、許可IPルールを作成
  dynamic "rule" {
    for_each = length(var.allowed_ip_addresses) > 0 ? [1] : []
    content {
      name     = "AllowSpecificIPs"
      priority = 1

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowed_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project_name}-${var.environment}-waf-allow-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf-cloudfront"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-waf-cloudfront"
    }
  )
}
