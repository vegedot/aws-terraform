include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  vpc_cidr = local.common_vars.locals.vpc_cidr
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.3.1"
}

inputs = {
  name             = "${local.project_name}-${local.environment}-sg-bastion"
  use_name_prefix  = false
  description      = "Security group for Bastion host (SSM only)"
  vpc_id           = dependency.vpc.outputs.vpc_id

  # SSM接続のみのため、インバウンドルール不要

  # VPC内のすべてのTCPポートへのアクセスを許可
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = local.vpc_cidr
      description = "Allow TCP traffic to VPC resources"
    }
  ]

  tags = {
    Name = "${local.project_name}-${local.environment}-sg-bastion"
  }
}
