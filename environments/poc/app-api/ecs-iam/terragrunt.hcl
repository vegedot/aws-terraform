include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  aws_region   = local.common_vars.locals.aws_region
}

dependency "dynamodb" {
  config_path = "../../database/dynamodb"

  mock_outputs = {
    dynamodb_table_arn = "arn:aws:dynamodb:ap-northeast-1:000000000000:table/mock-table"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/modules//ecs-iam"
}

inputs = {
  project_name            = local.project_name
  environment             = local.environment
  aws_region              = local.aws_region
  app_name                = "api"
  enable_dynamodb_access  = true
  dynamodb_table_arn      = dependency.dynamodb.outputs.dynamodb_table_arn
  enable_aurora_access    = true
  enable_xray             = true
}
