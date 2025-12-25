include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

terraform {
  source = "tfr:///terraform-aws-modules/lambda/aws?version=8.1.2"
}

inputs = {
  # Lambda@Edge must be created in us-east-1
  region = "us-east-1"

  function_name = "${local.project_name}-${local.environment}-edge-viewer-request"
  description   = "Lambda@Edge function for viewer request"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  publish       = true  # Lambda@Edge requires versioned functions

  # Lambda@Edge specific settings
  lambda_at_edge = true

  # Pythonが利用できない場合は手動でzipファイルを作成してください
  # cd lambda-edge/viewer-request && npm install && zip -r ../../lambda-edge.zip .
  create_package      = false
  local_existing_package = "${dirname(find_in_parent_folders("root.hcl"))}/lambda-edge.zip"

  # 注意: 初回デプロイ前に上記のコマンドでzipファイルを作成する必要があります
  # source_path = [
  #   {
  #     path = "${dirname(find_in_parent_folders("root.hcl"))}/lambda-edge/viewer-request"
  #     commands = [
  #       "npm install",
  #       ":zip"
  #     ]
  #   }
  # ]

  # Lambda@Edge IAM role
  create_role = true
  role_name   = "${local.project_name}-${local.environment}-lambda-edge-role"

  # CloudWatch Logs (Lambda@Edge logs go to edge locations)
  cloudwatch_logs_retention_in_days = 7

  tags = {
    Name = "${local.project_name}-${local.environment}-lambda-edge-viewer-request"
  }
}
