include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  aws_region   = local.common_vars.locals.aws_region
}

terraform {
  source = "${get_repo_root()}/modules//ecs-iam"
}

inputs = {
  project_name            = local.project_name
  environment             = local.environment
  aws_region              = local.aws_region
  app_name                = "web"
  enable_dynamodb_access  = false
  enable_aurora_access    = false
  enable_xray             = true
  # dynamodb_table_arn is not required when enable_dynamodb_access = false
}
