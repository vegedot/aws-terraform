# VPC outputs
output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = var.private_subnets
}

# Security group outputs
output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = var.ecs_security_group_id
}

# ALB outputs
output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = var.alb_target_group_arn
}

# ECR outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = var.ecr_repository_url
}

# ECS Cluster outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = var.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = var.ecs_cluster_arn
}

# IAM Role outputs
output "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = var.task_execution_role_arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = var.task_role_arn
}

# Convenience outputs for ecspresso
output "network_configuration" {
  description = "Network configuration for ECS service (for ecspresso)"
  value = {
    awsvpcConfiguration = {
      subnets        = var.private_subnets
      securityGroups = [var.ecs_security_group_id]
      assignPublicIp = "DISABLED"
    }
  }
}

output "load_balancers" {
  description = "Load balancer configuration for ECS service (for ecspresso)"
  value = [
    {
      targetGroupArn = var.alb_target_group_arn
      containerName  = "api"
      containerPort  = 8080
    }
  ]
}
