include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  common_tags = local.common_vars.locals.common_tags
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id         = "vpc-00000000000000000"
    vpc_cidr_block = "10.0.0.0/16"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/modules/security-groups//"
}

inputs = {
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = dependency.vpc.outputs.vpc_cidr_block
  project_name = local.project_name
  environment  = local.environment
  common_tags  = local.common_tags
}
