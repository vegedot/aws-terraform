include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  common_tags  = local.common_vars.locals.common_tags
}

terraform {
  source = "tfr:///terraform-aws-modules/dynamodb-table/aws?version=4.0.0"
}

inputs = {
  name     = "${local.project_name}-${local.environment}-dynamodb-main"
  hash_key = "id"

  # PoC環境のためオンデマンド課金
  billing_mode = "PAY_PER_REQUEST"

  # 属性定義
  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  # 削除保護を無効化（PoC環境）
  deletion_protection_enabled = false

  # Point-in-Time Recovery（PITR）
  point_in_time_recovery_enabled = true

  # サーバーサイド暗号化
  server_side_encryption_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.environment}-dynamodb-main"
    }
  )
}
