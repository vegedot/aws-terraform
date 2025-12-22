include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    vpc_id          = "vpc-00000000000000000"
    private_subnets = ["subnet-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../../network/security-groups"

  mock_outputs = {
    eks_cluster_sg_id = "sg-00000000000000000"
    eks_node_sg_id    = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.10.1"
}

inputs = {
  cluster_name    = "${local.project_name}-${local.environment}-eks-scalardb"
  cluster_version = "1.28"

  # VPC Configuration
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  # Control Plane Networking
  cluster_endpoint_public_access = true   # PoC環境のため
  cluster_endpoint_private_access = true

  # Security Groups
  cluster_security_group_id            = dependency.security_groups.outputs.eks_cluster_sg_id
  cluster_additional_security_group_ids = []

  # Node Security Group
  node_security_group_id = dependency.security_groups.outputs.eks_node_sg_id

  # Cluster Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups は別ファイルで定義
  eks_managed_node_groups = {}

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # CloudWatch Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name = "${local.project_name}-${local.environment}-eks-scalardb"
  }
}
