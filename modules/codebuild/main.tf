# CodeBuild Service Role
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role-${var.app_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-codebuild-role-${var.app_name}"
  }
}

# CloudWatch Logs policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_cloudwatch_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-cloudwatch-${var.app_name}"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}-${var.environment}-*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}-${var.environment}-*:*"
        ]
      }
    ]
  })
}

# S3 access policy for CodeBuild (source bucket)
resource "aws_iam_role_policy" "codebuild_s3_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-s3-${var.app_name}"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          var.source_bucket_arn,
          "${var.source_bucket_arn}/*"
        ]
      }
    ]
  })
}

# ECR access policy for CodeBuild (push images)
resource "aws_iam_role_policy" "codebuild_ecr_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-ecr-${var.app_name}"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

# CloudWatch Logs log group with retention policy
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-${var.app_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-codebuild-logs-${var.app_name}"
  }
}

# CodeBuild Project
resource "aws_codebuild_project" "this" {
  name          = "${var.project_name}-${var.environment}-build-${var.app_name}"
  description   = "Build and push ${var.app_name} container image to ECR"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = var.build_timeout

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/${var.project_name}-${var.environment}-${var.app_name}"
    }
  }

  source {
    type      = "S3"
    location  = "${var.source_bucket_name}/${var.source_object_key}"
    buildspec = var.buildspec_content != "" ? var.buildspec_content : null
  }

  # VPC configuration (optional - omit for cost savings in PoC)
  dynamic "vpc_config" {
    for_each = var.vpc_id != null && var.vpc_id != "" ? [1] : []
    content {
      vpc_id             = var.vpc_id
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-codebuild-${var.app_name}"
    Application = var.app_name
  }
}
