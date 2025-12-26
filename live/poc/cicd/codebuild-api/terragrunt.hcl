include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment    = local.common_vars.locals.environment
  project_name   = local.common_vars.locals.project_name
  aws_region     = local.common_vars.locals.aws_region
  aws_account_id = local.common_vars.locals.aws_account_id
}

terraform {
  source = "${get_repo_root()}/modules//codebuild"
}

dependency "s3_source" {
  config_path = "../s3-source"
}

dependency "ecr" {
  config_path = "../../app-api/ecr"
}

inputs = {
  project_name   = local.project_name
  environment    = local.environment
  aws_region     = local.aws_region
  aws_account_id = local.aws_account_id
  app_name       = "api"

  # S3 source configuration
  source_bucket_name = dependency.s3_source.outputs.s3_bucket_id
  source_bucket_arn  = dependency.s3_source.outputs.s3_bucket_arn
  source_object_key  = "api/source.zip"

  # ECR configuration
  ecr_repository_arn = dependency.ecr.outputs.repository_arn
  ecr_repository_url = dependency.ecr.outputs.repository_url

  # VPC configuration (omitted for cost savings - runs outside VPC)
  # vpc_id             = dependency.vpc.outputs.vpc_id
  # subnet_ids         = dependency.vpc.outputs.private_subnets
  # security_group_ids = [dependency.codebuild_sg.outputs.security_group_id]

  # Build configuration for Java application
  compute_type = "BUILD_GENERAL1_SMALL"
  build_image  = "aws/codebuild/standard:7.0"  # Amazon Linux 2, Java 17
  build_timeout = 60

  # Environment variables
  environment_variables = {
    RUNTIME = "java"
  }

  # Buildspec: Use buildspec.yml in source code
  # If source code doesn't have buildspec.yml, uncomment buildspec_content below
  buildspec_content = ""

  # Sample inline buildspec (use this if source code doesn't have buildspec.yml)
  # buildspec_content = <<-EOT
  # version: 0.2
  #
  # phases:
  #   pre_build:
  #     commands:
  #       - echo Logging in to Amazon ECR...
  #       - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  #       - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
  #       - IMAGE_TAG=$${COMMIT_HASH:-latest}
  #   build:
  #     commands:
  #       - echo Build started on `date`
  #       - echo Building the Docker image...
  #       - docker build -t $ECR_REPOSITORY_URI:latest .
  #       - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$IMAGE_TAG
  #   post_build:
  #     commands:
  #       - echo Build completed on `date`
  #       - echo Pushing the Docker images...
  #       - docker push $ECR_REPOSITORY_URI:latest
  #       - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
  #       - echo Writing image definitions file...
  #       - printf '[{"name":"api","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
  #
  # artifacts:
  #   files:
  #     - imagedefinitions.json
  # EOT
}
