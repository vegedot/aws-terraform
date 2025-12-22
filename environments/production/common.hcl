locals {
  environment = "production"
  aws_region  = "ap-northeast-1"

  # Project name
  project_name = "myapp"

  # VPC CIDR
  vpc_cidr = "10.2.0.0/16"

  # Availability Zones (production環境では3 AZs)
  azs = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

  # Subnet CIDRs
  public_subnets   = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnets  = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
  database_subnets = ["10.2.20.0/24", "10.2.21.0/24", "10.2.22.0/24"]

  # Tags
  common_tags = {
    Environment = "production"
    Project     = "myapp"
    ManagedBy   = "Terraform"
  }
}
