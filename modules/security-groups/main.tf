# ALB Security Group
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-alb"
  use_name_prefix  = false
  description      = "Security group for ALB"
  vpc_id           = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from anywhere"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# ECS Security Group
module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-ecs"
  use_name_prefix  = false
  description      = "Security group for ECS tasks"
  vpc_id           = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "HTTP from ALB"
    },
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Application port from ALB"
    },
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Alternative application port from ALB"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 3

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# Aurora Security Group
module "aurora_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-aurora"
  use_name_prefix  = false
  description      = "Security group for Aurora MySQL"
  vpc_id           = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.ecs_sg.security_group_id
      description              = "MySQL from ECS"
    },
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.bastion_sg.security_group_id
      description              = "MySQL from Bastion"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 2

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# Bastion Security Group
# SSM接続のみ、SSH接続は無効化
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-bastion"
  use_name_prefix  = false
  description      = "Security group for Bastion host (SSM only)"
  vpc_id           = var.vpc_id

  # SSM接続のみのため、インバウンドルール不要

  # VPC内のリソースへのアクセスのみ許可
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.vpc_cidr
      description = "Allow outbound to VPC resources only"
    }
  ]

}

# EKS Cluster Security Group (Control Plane)
module "eks_cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-eks-cluster"
  use_name_prefix  = false
  description      = "Security group for EKS cluster control plane"
  vpc_id           = var.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# EKS Node Security Group (Worker Nodes)
module "eks_node_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name             = "${var.project_name}-${var.environment}-sg-eks-node"
  use_name_prefix  = false
  description      = "Security group for EKS worker nodes"
  vpc_id           = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
      source_security_group_id = module.eks_cluster_sg.security_group_id
      description              = "Allow all from EKS control plane"
    },
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
      source_security_group_id = module.ecs_sg.security_group_id
      description              = "Allow all from ECS tasks (for ScalarDB access)"
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.bastion_sg.security_group_id
      description              = "Allow HTTPS from Bastion (for kubectl)"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 3

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

}

# Allow Bastion to connect to ECS
resource "aws_security_group_rule" "bastion_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.security_group_id
  security_group_id        = module.ecs_sg.security_group_id
  description              = "Allow Bastion to connect to ECS tasks"
}

# Allow EKS nodes to connect to Aurora
resource "aws_security_group_rule" "eks_to_aurora" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.eks_node_sg.security_group_id
  security_group_id        = module.aurora_sg.security_group_id
  description              = "Allow EKS nodes to connect to Aurora"
}

# Allow EKS nodes to communicate with each other
resource "aws_security_group_rule" "eks_node_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.eks_node_sg.security_group_id
  security_group_id        = module.eks_node_sg.security_group_id
  description              = "Allow EKS nodes to communicate with each other"
}

# Allow EKS control plane to communicate with nodes
resource "aws_security_group_rule" "eks_cluster_to_node" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.eks_node_sg.security_group_id
  security_group_id        = module.eks_cluster_sg.security_group_id
  description              = "Allow nodes to communicate with control plane"
}

# Allow Bastion to access EKS control plane API
resource "aws_security_group_rule" "bastion_to_eks_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.security_group_id
  security_group_id        = module.eks_cluster_sg.security_group_id
  description              = "Allow Bastion to access EKS control plane (kubectl)"
}
