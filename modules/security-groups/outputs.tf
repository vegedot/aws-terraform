output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = module.alb_sg.security_group_id
}

output "bastion_sg_id" {
  description = "Bastion Security Group ID"
  value       = module.bastion_sg.security_group_id
}
