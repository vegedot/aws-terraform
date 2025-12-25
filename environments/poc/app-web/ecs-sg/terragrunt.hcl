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

dependency "alb_sg" {
  config_path = "../alb-sg"

  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "bastion_sg" {
  config_path = "../../bastion/ec2-sg"

  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.3.1"
}

inputs = {
  name             = "${local.project_name}-${local.environment}-sg-ecs-web"
  use_name_prefix  = false
  description      = "Security group for ECS WEB tasks"
  vpc_id           = dependency.vpc.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = dependency.alb_sg.outputs.security_group_id
      description              = "HTTP from ALB"
    },
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = dependency.alb_sg.outputs.security_group_id
      description              = "Application port from ALB"
    },
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = dependency.alb_sg.outputs.security_group_id
      description              = "Alternative application port from ALB"
    },
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      source_security_group_id = dependency.bastion_sg.outputs.security_group_id
      description              = "Allow Bastion to connect to ECS tasks"
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
    Name = "${local.project_name}-${local.environment}-sg-ecs-web"
  }
}
