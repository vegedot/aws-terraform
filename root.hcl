locals {
  # 環境固有の設定を読み込み
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # AWS設定
  aws_region     = local.common_vars.locals.aws_region
  aws_profile    = local.common_vars.locals.aws_profile
  aws_account_id = local.common_vars.locals.aws_account_id

  # Terraform State用S3バケット
  tfstate_bucket = local.common_vars.locals.tfstate_bucket

  # 環境名（common.hclから取得）
  environment = local.common_vars.locals.environment

  # 共通タグ（root.hclで定義、環境ごとの編集不可）
  common_tags = {
    Environment = local.environment  # common.hclから取得
    Project     = "myapp"            # 全環境共通（固定値）
    ManagedBy   = "Terraform"        # 全環境共通（固定値）
  }
}

# Generate Terraform version requirement
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.14.3"
}
EOF
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.aws_profile}"

  # すべてのリソースに自動的に適用されるタグ
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
# Terraform 1.10+ の use_lockfile 機能を使用（DynamoDB不要）
remote_state {
  backend = "s3"
  config = {
    encrypt      = true
    bucket       = local.tfstate_bucket
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.aws_region
    profile      = local.aws_profile
    use_lockfile = true  # Terraform 1.10+ のネイティブS3ロック機能
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
