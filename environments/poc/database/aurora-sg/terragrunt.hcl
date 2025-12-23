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

dependency "eks_sg" {
  config_path = "../../app-scalardb/eks-sg"

  mock_outputs = {
    eks_node_sg_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.3.1"
}

inputs = {
  name             = "${local.project_name}-${local.environment}-sg-aurora"
  use_name_prefix  = false
  description      = "Security group for Aurora MySQL"
  vpc_id           = dependency.vpc.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.ecs_api_sg.outputs.security_group_id
      description              = "MySQL from ECS API"
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.ecs_web_sg.outputs.security_group_id
      description              = "MySQL from ECS WEB"
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.security_groups.outputs.bastion_sg_id
      description              = "MySQL from Bastion"
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = dependency.eks_sg.outputs.eks_node_sg_id
      description              = "MySQL from EKS nodes"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 4

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

  tags = {
    Name = "${local.project_name}-${local.environment}-sg-aurora"
  }
}
