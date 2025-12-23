output "bastion_access_entry_arn" {
  description = "ARN of the Bastion access entry"
  value       = aws_eks_access_entry.bastion.access_entry_arn
}

output "bastion_access_entry_id" {
  description = "ID of the Bastion access entry"
  value       = aws_eks_access_entry.bastion.id
}
