output "alb_id" {
  description = "The ID of the load balancer"
  value       = module.alb.id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the load balancer"
  value       = module.alb.zone_id
}

output "target_groups" {
  description = "Map of target groups"
  value       = module.alb.target_groups
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_groups
}
