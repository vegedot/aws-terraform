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
    vpc_id          = "vpc-00000000000000000"
    public_subnets  = ["subnet-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../../network/security-groups"

  mock_outputs = {
    alb_sg_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/modules/alb//"
}

inputs = {
  vpc_id            = dependency.vpc.outputs.vpc_id
  public_subnets    = dependency.vpc.outputs.public_subnets
  alb_sg_id         = dependency.security_groups.outputs.alb_sg_id
  project_name      = local.project_name
  environment       = local.environment

  # API ALB specific configuration
  alb_type          = "api"
  backend_port      = 3000
  health_check_path = "/health"
}
