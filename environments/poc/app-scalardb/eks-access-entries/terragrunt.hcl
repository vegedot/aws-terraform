include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

dependency "eks_cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_name = "${local.project_name}-${local.environment}-eks-scalardb"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "bastion" {
  config_path = "../../bastion/ec2"

  mock_outputs = {
    iam_role_arn = "arn:aws:iam::123456789012:role/${local.project_name}-${local.environment}-role-bastion"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/modules/eks-access-entries//"
}

inputs = {
  cluster_name          = dependency.eks_cluster.outputs.cluster_name
  bastion_iam_role_arn  = dependency.bastion.outputs.iam_role_arn
  project_name          = local.project_name
  environment           = local.environment
}
