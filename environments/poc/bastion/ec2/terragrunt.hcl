include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
  common_tags = local.common_vars.locals.common_tags
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs = {
    private_subnets = ["subnet-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../../network/security-groups"

  mock_outputs = {
    bastion_sg_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=6.1.5"
}

inputs = {
  name = "${local.project_name}-${local.environment}-ec2-bastion"

  # Amazon Linux 2023 AMI ID (ap-northeast-1)
  # 担当者が定期的に更新すること
  # 最新AMI: https://ap-northeast-1.console.aws.amazon.com/ec2/home?region=ap-northeast-1#LaunchInstances:
  ami                    = local.common_vars.locals.bastion_ami_id
  instance_type          = "t3.micro"
  monitoring             = true
  vpc_security_group_ids = [dependency.security_groups.outputs.bastion_sg_id]
  subnet_id              = dependency.vpc.outputs.private_subnets[0]

  # SSM接続のみ、パブリックIPは不要
  associate_public_ip_address = false

  # User data (SSM Agentはプリインストール済み)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user

              # Install mysql client
              yum install -y mariadb105
              EOF

  # IAM instance profile for SSM and ECS access
  create_iam_instance_profile = true
  iam_role_name               = "${local.project_name}-${local.environment}-role-bastion"
  iam_role_description        = "IAM role for bastion host"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonECSReadOnlyAccess      = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  }

  tags = local.common_tags
}
