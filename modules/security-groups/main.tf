# ALB Security Group
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-alb"
  use_name_prefix  = false
  description      = "Security group for ALB"
  vpc_id           = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from anywhere"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# Bastion Security Group
# SSM接続のみ、SSH接続は無効化
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-bastion"
  use_name_prefix  = false
  description      = "Security group for Bastion host (SSM only)"
  vpc_id           = var.vpc_id

  # SSM接続のみのため、インバウンドルール不要

  # VPC内のリソースへのアクセスのみ許可
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.vpc_cidr
      description = "Allow outbound to VPC resources only"
    }
  ]

}
