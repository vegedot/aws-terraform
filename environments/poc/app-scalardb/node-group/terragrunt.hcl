include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  azs          = local.common_vars.locals.azs
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    private_subnets = ["subnet-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "eks_cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_name                   = "mock-eks-cluster"
    cluster_security_group_id      = "sg-00000000000000000"
    node_security_group_id         = "sg-00000000000000000"
    eks_managed_node_groups_autoscaling_group_names = []
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws//modules/eks-managed-node-group?version=21.10.1"
}

inputs = {
  name            = "${local.project_name}-${local.environment}-scalardb-nodes"
  cluster_name    = dependency.eks_cluster.outputs.cluster_name
  cluster_version = "1.28"

  # Subnet Configuration
  subnet_ids = dependency.vpc.outputs.private_subnets

  # PoC環境: 最小構成
  min_size     = 2
  max_size     = 4
  desired_size = 2

  # Instance Configuration
  instance_types = ["t3.medium"]  # PoC環境用
  capacity_type  = "ON_DEMAND"

  # Disk Configuration
  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 50
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 125
        encrypted             = true
        delete_on_termination = true
      }
    }
  }

  # Security Group
  vpc_security_group_ids = [dependency.eks_cluster.outputs.node_security_group_id]

  # IAM Role
  create_iam_role          = true
  iam_role_name            = "${local.project_name}-${local.environment}-eks-node-role"
  iam_role_use_name_prefix = false
  iam_role_description     = "EKS managed node group IAM role for ScalarDB"

  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  # Labels and Taints for ScalarDB workloads
  labels = {
    workload = "scalardb"
  }

  # User Data
  enable_bootstrap_user_data = true
  pre_bootstrap_user_data = <<-EOT
    #!/bin/bash
    # Additional setup for ScalarDB if needed
    echo "Configuring node for ScalarDB workloads"
  EOT

  tags = {
    Name = "${local.project_name}-${local.environment}-scalardb-node"
  }
}
