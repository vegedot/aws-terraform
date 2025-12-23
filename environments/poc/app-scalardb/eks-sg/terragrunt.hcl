include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../../network/security-groups"

  mock_outputs = {
    bastion_sg_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "ecs_api_sg" {
  config_path = "../../app-api/ecs-sg"

  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "ecs_web_sg" {
  config_path = "../../app-web/ecs-sg"

  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/modules/eks-sg//"
}

inputs = {
  vpc_id        = dependency.vpc.outputs.vpc_id
  project_name  = local.project_name
  environment   = local.environment
  ecs_api_sg_id = dependency.ecs_api_sg.outputs.security_group_id
  ecs_web_sg_id = dependency.ecs_web_sg.outputs.security_group_id
  bastion_sg_id = dependency.security_groups.outputs.bastion_sg_id
}
