include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment  = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  aws_account_id = local.common_vars.locals.aws_account_id
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=4.0.0"
}

inputs = {
  bucket = "${local.project_name}-${local.environment}-web-content-${local.aws_account_id}"

  # Block all public access - we'll use CloudFront with OAC
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle rules for PoC cleanup
  lifecycle_rule = [
    {
      id      = "delete-old-versions"
      enabled = true

      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]

  tags = merge(
    {
      Name = "${local.project_name}-${local.environment}-web-content"
    }
  )
}
