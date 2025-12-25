output "http_ingress_sg_id" {
  description = "HTTP Ingress Security Group ID (generic policy for internet HTTP access)"
  value       = module.http_ingress_sg.security_group_id
}

output "https_ingress_sg_id" {
  description = "HTTPS Ingress Security Group ID (generic policy for internet HTTPS access)"
  value       = module.https_ingress_sg.security_group_id
}

output "vpc_egress_sg_id" {
  description = "VPC Egress Security Group ID (generic policy for VPC egress)"
  value       = module.vpc_egress_sg.security_group_id
}
