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
      source_security_group_id = var.ecs_api_sg_id
      description              = "Allow all from ECS API tasks (for ScalarDB access)"
    },
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
      source_security_group_id = var.ecs_web_sg_id
      description              = "Allow all from ECS WEB tasks (for ScalarDB access)"
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = var.bastion_sg_id
      description              = "Allow HTTPS from Bastion (for kubectl)"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 4

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
  source_security_group_id = var.bastion_sg_id
  security_group_id        = module.eks_cluster_sg.security_group_id
  description              = "Allow Bastion to access EKS control plane (kubectl)"
}
