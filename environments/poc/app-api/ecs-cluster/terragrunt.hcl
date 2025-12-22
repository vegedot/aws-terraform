include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  common_tags = local.common_vars.locals.common_tags
}

terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//modules/cluster?version=5.7.0"
}

inputs = {
  cluster_name = "${local.project_name}-${local.environment}-cluster-api"

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 0
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.environment}-cluster-api"
    }
  )
}
