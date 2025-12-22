# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  comment             = "${var.project_name}-${var.environment} CloudFront Distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_200"
  wait_for_deployment = false

  # Origin for S3 static content
  origin = {
    s3_static = {
      domain_name              = var.s3_bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    }

    # Origin for WEB ALB
    web_alb = {
      domain_name = var.web_alb_dns_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }

    # Origin for API ALB
    api_alb = {
      domain_name = var.api_alb_dns_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default cache behavior (S3 static content)
  default_cache_behavior = {
    target_origin_id       = "s3_static"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3origin.id
  }

  # Cache behavior for WEB ALB
  ordered_cache_behavior = [
    {
      path_pattern           = "/app/*"
      target_origin_id       = "web_alb"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      cache_policy_id = data.aws_cloudfront_cache_policy.web_cache_policy.id
    },
    # Cache behavior for API ALB
    {
      path_pattern           = "/api/*"
      target_origin_id       = "api_alb"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      cache_policy_id = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    }
  ]

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  web_acl_id = var.web_acl_id

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn"
  }
}

# Update S3 bucket policy to allow CloudFront OAC
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# Data sources for managed cache policies
data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "web_cache_policy" {
  name = var.web_cache_policy_name
}

data "aws_cloudfront_origin_request_policy" "managed_cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}
