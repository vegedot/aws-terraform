# EKS Access Entry for Bastion
resource "aws_eks_access_entry" "bastion" {
  cluster_name      = var.cluster_name
  principal_arn     = var.bastion_iam_role_arn
  kubernetes_groups = []
  type              = "STANDARD"

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-access-bastion"
  }
}

# Policy Association for Bastion Access Entry
resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = var.cluster_name
  principal_arn = var.bastion_iam_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion]
}
