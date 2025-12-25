include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules//waf"
}

inputs = {
  project_name         = local.project_name
  environment          = local.environment
  allowed_ip_addresses = local.common_vars.locals.allowed_ip_addresses
}
