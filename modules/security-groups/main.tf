# HTTP Ingress Security Group (Generic Policy)
# 汎用ポリシー: インターネットからのHTTPアクセスを許可
# 必要なリソース（ALB等）で使用可能
# Note: Security Groupはステートフルなので、egressルールは不要
module "http_ingress_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-http-ingress"
  use_name_prefix  = false
  description      = "Generic policy for HTTP ingress from internet"
  vpc_id           = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere"
    }
  ]

}

# HTTPS Ingress Security Group (Generic Policy)
# 汎用ポリシー: インターネットからのHTTPSアクセスを許可
# 必要なリソース（ALB等）で使用可能
# Note: Security Groupはステートフルなので、egressルールは不要
module "https_ingress_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-https-ingress"
  use_name_prefix  = false
  description      = "Generic policy for HTTPS ingress from internet"
  vpc_id           = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from anywhere"
    }
  ]

}

# VPC Egress Security Group (Generic Policy)
# 汎用ポリシー: VPC内の全TCPポートへのアクセスを許可
# 必要なリソース（Bastion等の管理用リソース）で使用可能
module "vpc_egress_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-vpc-egress"
  use_name_prefix  = false
  description      = "Generic policy for VPC egress (all TCP ports)"
  vpc_id           = var.vpc_id

  # インバウンドルール不要

  # VPC内のすべてのTCPポートへのアクセスを許可
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr
      description = "Allow TCP traffic to VPC resources"
    }
  ]

}
