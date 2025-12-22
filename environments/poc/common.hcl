locals {
  environment = "poc"

  # AWS Configuration
  aws_region     = "ap-northeast-1"
  aws_profile    = "vegedot-dev"  # AWSプロファイル名（~/.aws/credentials）
  aws_account_id = "734882177948"  # 実際のAWSアカウントIDに更新すること

  # Terraform State S3 Bucket
  tfstate_bucket = "${local.project_name}-${local.environment}-tfstate-${local.aws_account_id}"

  # Project name
  project_name = "myapp"

  # VPC CIDR
  vpc_cidr = "10.0.0.0/16"

  # Availability Zone (single AZ for PoC)
  azs = ["ap-northeast-1a"]

  # Subnet CIDRs
  public_subnets   = ["10.0.1.0/24"]
  private_subnets  = ["10.0.10.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"] # Aurora requires at least 2 AZs

  # AMI IDs (定期的に更新すること)
  # Amazon Linux 2023 最新AMI: https://ap-northeast-1.console.aws.amazon.com/ec2/home?region=ap-northeast-1#AMIs:visibility=public-images;name=al2023-ami;sort=name
  bastion_ami_id = "ami-0d48337b7d3c86f62" # Amazon Linux 2023 (ap-northeast-1) - 要更新

  # WAF Allowed IP addresses (CIDR notation)
  # 空の場合: IP制限なし（PoC/開発環境）
  # IPを指定: 指定IPのみ許可（本番環境）
  allowed_ip_addresses = []

  # CloudFront Cache Policy for WEB application
  # PoC/開発: Managed-CachingDisabled (キャッシュなし)
  # 本番: Managed-CachingOptimized (キャッシュあり)
  web_cache_policy_name = "Managed-CachingDisabled"

  # Tags
  common_tags = {
    Environment = "poc"
    Project     = "myapp"
    ManagedBy   = "Terraform"
  }
}
