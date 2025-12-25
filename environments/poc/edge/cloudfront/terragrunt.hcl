include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

dependency "s3_web" {
  config_path = "../../app-web/s3-web"

  mock_outputs = {
    s3_bucket_id                          = "mock-bucket"
    s3_bucket_arn                         = "arn:aws:s3:::mock-bucket"
    s3_bucket_bucket_regional_domain_name = "mock-bucket.s3.ap-northeast-1.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "web_alb" {
  config_path = "../../app-web/alb"

  mock_outputs = {
    alb_dns_name = "mock-web-alb.ap-northeast-1.elb.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "api_alb" {
  config_path = "../../app-api/alb"

  mock_outputs = {
    alb_dns_name = "mock-api-alb.ap-northeast-1.elb.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "waf" {
  config_path = "../waf"

  mock_outputs = {
    web_acl_id = "arn:aws:wafv2:us-east-1:000000000000:global/webacl/mock/00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "lambda_edge" {
  config_path = "../lambda-edge"

  mock_outputs = {
    lambda_function_qualified_arn = "arn:aws:lambda:us-east-1:000000000000:function:mock-function:1"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/cloudfront//"
}

inputs = {
  s3_bucket_id                       = dependency.s3_web.outputs.s3_bucket_id
  s3_bucket_arn                      = dependency.s3_web.outputs.s3_bucket_arn
  s3_bucket_regional_domain_name     = dependency.s3_web.outputs.s3_bucket_bucket_regional_domain_name
  web_alb_dns_name                   = dependency.web_alb.outputs.alb_dns_name
  api_alb_dns_name                   = dependency.api_alb.outputs.alb_dns_name
  web_acl_id                         = dependency.waf.outputs.web_acl_id
  web_cache_policy_name              = local.common_vars.locals.web_cache_policy_name
  lambda_edge_viewer_request_arn     = dependency.lambda_edge.outputs.lambda_function_qualified_arn
  project_name                       = local.project_name
  environment                        = local.environment
}
