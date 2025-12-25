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

dependency "aurora_sg" {
  config_path = "../aurora-sg"

  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/rds-aurora/aws?version=10.0.2"
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

  vpc_id                   = dependency.vpc.outputs.vpc_id
  db_subnet_group_name     = dependency.vpc.outputs.database_subnet_group_name
  vpc_security_group_ids   = [dependency.aurora_sg.outputs.security_group_id]
  create_db_subnet_group   = false
  create_security_group    = false

  # PoC環境のため最小構成
  instances = {
    one = {
      identifier          = "${local.project_name}-${local.environment}-aurora-main-1"
      instance_class      = "db.t3.medium"
      publicly_accessible = false
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = {
    Name = "${local.project_name}-${local.environment}-aurora-main"
  }
}
