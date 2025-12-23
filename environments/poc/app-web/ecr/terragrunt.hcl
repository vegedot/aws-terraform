include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws?version=2.4.0"
}

inputs = {
  repository_name = "${local.project_name}-${local.environment}-web"

  # Image scanning for security vulnerabilities
  repository_image_tag_mutability = "MUTABLE"  # PoC環境のため。本番環境ではIMMUTABLEを推奨
  repository_image_scan_on_push   = true

  # Lifecycle policy to manage image retention
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # Enable encryption
  repository_encryption_type = "AES256"

  # Allow force delete for PoC environment
  repository_force_delete = true

  tags = {
    Name        = "${local.project_name}-${local.environment}-ecr-web"
    Application = "WEB"
    Runtime     = "Node.js"
  }
}
