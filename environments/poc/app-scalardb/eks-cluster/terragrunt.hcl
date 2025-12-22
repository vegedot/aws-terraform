include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment    = local.common_vars.locals.environment
  project_name   = local.common_vars.locals.project_name
  aws_account_id = local.common_vars.locals.aws_account_id
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

  # IAM Role for EKS Cluster
  create_iam_role               = true
  iam_role_name                 = "${local.project_name}-${local.environment}-eks-cluster-role"
  iam_role_use_name_prefix      = false
  iam_role_description          = "IAM role for EKS cluster"
  iam_role_tags = {
    Name = "${local.project_name}-${local.environment}-eks-cluster-role"
  }

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

  # Access Entries - Bastion host kubectl access
  # NOTE: Bastion IAM Roleが先に作成されている必要があります
  # 初回デプロイ時: Bastion → EKS の順でデプロイ
  # または、EKSを先にデプロイする場合は以下をコメントアウトしてから後で追加
  access_entries = {
    bastion = {
      principal_arn = "arn:aws:iam::${local.aws_account_id}:role/${local.project_name}-${local.environment}-role-bastion"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # CloudWatch Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name = "${local.project_name}-${local.environment}-eks-scalardb"
  }
}
