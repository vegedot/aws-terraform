include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  vpc_cidr = local.common_vars.locals.vpc_cidr
  azs = local.common_vars.locals.azs
  public_subnets = local.common_vars.locals.public_subnets
  private_subnets = local.common_vars.locals.private_subnets
  database_subnets = local.common_vars.locals.database_subnets
  common_tags = local.common_vars.locals.common_tags
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.1.2"
}

inputs = {
  name = "${local.project_name}-${local.environment}-vpc"
  cidr = local.vpc_cidr

  azs              = concat(local.azs, ["ap-northeast-1c"]) # Aurora requires at least 2 AZs
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  # Subnet names following naming convention
  public_subnet_names   = ["${local.project_name}-${local.environment}-subnet-public-web-1a"]
  private_subnet_names  = ["${local.project_name}-${local.environment}-subnet-private-app-1a"]
  database_subnet_names = [
    "${local.project_name}-${local.environment}-subnet-private-db-1a",
    "${local.project_name}-${local.environment}-subnet-private-db-1c"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true # PoC環境のため1つのNAT Gatewayのみ
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Resource naming
  igw_tags = {
    Name = "${local.project_name}-${local.environment}-igw"
  }

  nat_gateway_tags = {
    Name = "${local.project_name}-${local.environment}-nat-1a"
  }

  public_route_table_tags = {
    Name = "${local.project_name}-${local.environment}-rtb-public"
  }

  private_route_table_tags = {
    Name = "${local.project_name}-${local.environment}-rtb-private"
  }

  database_route_table_tags = {
    Name = "${local.project_name}-${local.environment}-rtb-db"
  }

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.project_name}-${local.environment}-dbsubnet"

  tags = local.common_tags
}
