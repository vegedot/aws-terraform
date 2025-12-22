include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  environment = local.common_vars.locals.environment
  project_name = local.common_vars.locals.project_name
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
              dnf update -y

              # Install git
              dnf install -y git

              # Install Docker
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user

              # Install mysql client
              dnf install -y mariadb105

              # Install Java (Amazon Corretto 17)
              dnf install -y java-17-amazon-corretto-devel

              # Install kubectl
              cat <<'KUBECTL_REPO' > /etc/yum.repos.d/kubernetes.repo
              [kubernetes]
              name=Kubernetes
              baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
              enabled=1
              gpgcheck=1
              gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
              KUBECTL_REPO
              dnf install -y kubectl

              # Install Helm
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

              # Configure kubectl for ssm-user (SSM Session Manager uses ssm-user)
              mkdir -p /home/ssm-user/.kube
              chown ssm-user:ssm-user /home/ssm-user/.kube

              # Configure EKS kubeconfig for app-scalardb cluster
              # Note: This will run after EKS cluster is created
              CLUSTER_NAME="${local.project_name}-${local.environment}-eks-scalardb"
              REGION="${local.common_vars.locals.aws_region}"

              # Create a script for ssm-user to update kubeconfig manually if needed
              cat > /home/ssm-user/update-kubeconfig.sh <<SCRIPT
              #!/bin/bash
              aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION --kubeconfig /home/ssm-user/.kube/config
              echo "Kubeconfig updated for cluster: $CLUSTER_NAME"
              kubectl get nodes
              SCRIPT

              chmod +x /home/ssm-user/update-kubeconfig.sh
              chown ssm-user:ssm-user /home/ssm-user/update-kubeconfig.sh

              # Try to configure kubeconfig automatically (may fail if EKS not yet created)
              su - ssm-user -c "aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION --kubeconfig /home/ssm-user/.kube/config" 2>/dev/null || echo "EKS cluster not ready yet. Run ~/update-kubeconfig.sh after EKS is created."

              # Set JAVA_HOME for ssm-user
              echo 'export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto' >> /home/ssm-user/.bashrc
              echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /home/ssm-user/.bashrc
              EOF

  # IAM instance profile for SSM and ECS access
  create_iam_instance_profile = true
  iam_role_name               = "${local.project_name}-${local.environment}-role-bastion"
  iam_role_description        = "IAM role for bastion host"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonECSReadOnlyAccess      = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  }

  # Inline IAM policy statements for EKS access
  iam_role_statements = {
    eks_access = {
      effect = "Allow"
      actions = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups",
        "eks:AccessKubernetesApi"
      ]
      resources = ["*"]
    }
  }
}
