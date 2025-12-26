output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.this.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.this.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild_role.arn
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild IAM role"
  value       = aws_iam_role.codebuild_role.name
}
