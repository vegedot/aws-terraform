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
    vpc_id                          = "vpc-00000000000000000"
    database_subnet_group_name      = "mock-db-subnet-group"
    private_subnets_cidr_blocks     = ["10.0.10.0/24"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../../network/security-groups"

  mock_outputs = {
    aurora_sg_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/rds-aurora/aws?version=9.0.0"
}

inputs = {
  name              = "${local.project_name}-${local.environment}-aurora-main"
  engine            = "aurora-mysql"
  engine_version    = "8.0.mysql_aurora.3.04.0"
  engine_mode       = "provisioned"
  storage_encrypted = true

  master_username = "admin"
  # WARNING: In production, use AWS Secrets Manager for password
  manage_master_user_password = true

  vpc_id               = dependency.vpc.outputs.vpc_id
  db_subnet_group_name = dependency.vpc.outputs.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = dependency.vpc.outputs.private_subnets_cidr_blocks
    }
  }

  # PoC環境のため最小構成
  instances = {
    one = {
      instance_class      = "db.t3.medium"
      publicly_accessible = false
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(
    {
      Name = "${local.project_name}-${local.environment}-aurora-main"
    }
  )
}
