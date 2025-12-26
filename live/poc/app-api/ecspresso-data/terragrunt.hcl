include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

terraform {
  source = "${get_repo_root()}/modules//ecspresso-data"
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id          = "vpc-00000000"
    private_subnets = ["subnet-00000000", "subnet-11111111"]
  }
}

dependency "ecs_sg" {
  config_path = "../ecs-sg"

  mock_outputs = {
    security_group_id = "sg-00000000"
  }
}

dependency "alb" {
  config_path = "../alb"

  mock_outputs = {
    target_groups = {
      api-tg-8080 = {
        arn = "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/mock/1234567890123456"
      }
    }
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs = {
    repository_url = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/mock-repo"
  }
}

dependency "ecs_cluster" {
  config_path = "../ecs-cluster"

  mock_outputs = {
    cluster_name = "mock-cluster"
    cluster_arn  = "arn:aws:ecs:ap-northeast-1:123456789012:cluster/mock-cluster"
  }
}

dependency "ecs_iam" {
  config_path = "../ecs-iam"

  mock_outputs = {
    task_execution_role_arn = "arn:aws:iam::123456789012:role/mock-execution-role"
    task_role_arn           = "arn:aws:iam::123456789012:role/mock-task-role"
  }
}

inputs = {
  project_name = local.project_name
  environment  = local.environment

  # VPC configuration
  vpc_id          = dependency.vpc.outputs.vpc_id
  private_subnets = dependency.vpc.outputs.private_subnets

  # Security group
  ecs_security_group_id = dependency.ecs_sg.outputs.security_group_id

  # ALB target group
  alb_target_group_arn = dependency.alb.outputs.target_groups["api-tg-8080"].arn

  # ECR
  ecr_repository_url = dependency.ecr.outputs.repository_url

  # ECS Cluster
  ecs_cluster_name = dependency.ecs_cluster.outputs.cluster_name
  ecs_cluster_arn  = dependency.ecs_cluster.outputs.cluster_arn

  # IAM Roles
  task_execution_role_arn = dependency.ecs_iam.outputs.task_execution_role_arn
  task_role_arn           = dependency.ecs_iam.outputs.task_role_arn
}
