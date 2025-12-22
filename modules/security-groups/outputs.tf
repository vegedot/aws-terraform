output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = module.alb_sg.security_group_id
}

output "ecs_sg_id" {
  description = "ECS Security Group ID"
  value       = module.ecs_sg.security_group_id
}

output "aurora_sg_id" {
  description = "Aurora Security Group ID"
  value       = module.aurora_sg.security_group_id
}

output "bastion_sg_id" {
  description = "Bastion Security Group ID"
  value       = module.bastion_sg.security_group_id
}

output "eks_cluster_sg_id" {
  description = "EKS Cluster Security Group ID"
  value       = module.eks_cluster_sg.security_group_id
}

output "eks_node_sg_id" {
  description = "EKS Node Security Group ID"
  value       = module.eks_node_sg.security_group_id
}
