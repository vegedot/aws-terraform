include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.2.0"
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id   = "vpc-00000000"
    vpc_cidr_block = "10.0.0.0/16"
  }
}

inputs = {
  name        = "${local.project_name}-${local.environment}-sg-codebuild"
  description = "Security group for CodeBuild projects"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # Egress rules for CodeBuild
  egress_with_cidr_blocks = [
    {
      description = "Allow all outbound traffic to internet (for DockerHub, ECR, etc.)"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${local.project_name}-${local.environment}-sg-codebuild"
  }
}
