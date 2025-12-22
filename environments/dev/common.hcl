locals {
  environment = "dev"
  aws_region  = "ap-northeast-1"

  # Project name
  project_name = "myapp"

  # VPC CIDR
  vpc_cidr = "10.1.0.0/16"

  # Availability Zones (dev環境では2 AZs)
  azs = ["ap-northeast-1a", "ap-northeast-1c"]

  # Subnet CIDRs
  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets  = ["10.1.10.0/24", "10.1.11.0/24"]
  database_subnets = ["10.1.20.0/24", "10.1.21.0/24"]

  # Tags
  common_tags = {
    Environment = "dev"
    Project     = "myapp"
    ManagedBy   = "Terraform"
  }
}
