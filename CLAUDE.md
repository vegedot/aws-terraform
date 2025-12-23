# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terragrunt + Terraform codebase for managing AWS infrastructure across multiple environments (PoC, Dev, Production). The architecture uses Terragrunt for environment configuration management and both terraform-aws-modules official modules and custom wrapper modules.

## Essential Commands

### Terragrunt Operations

```bash
# Deploy all resources in an environment
cd environments/poc
terragrunt run-all apply

# Deploy a specific resource
cd environments/poc/network/vpc
terragrunt apply

# Deploy by logical group
cd environments/poc/network
terragrunt run-all apply

# Plan changes
terragrunt plan
terragrunt run-all plan

# Destroy resources
terragrunt destroy
terragrunt run-all destroy

# Clear Terragrunt cache
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
```

### Version Requirements

- Terraform: 1.14.3
- Terragrunt: 0.63.6
- AWS CLI configured with profiles in ~/.aws/credentials

## Architecture

### Configuration Hierarchy

1. **root.hcl**: Root-level configuration defining AWS provider, remote state (S3 with use_lockfile), and region settings
2. **environments/{env}/common.hcl**: Environment-specific variables (AWS account ID, region, profile, CIDR blocks, AMI IDs, tags)
3. **environments/{env}/{group}/{resource}/terragrunt.hcl**: Individual resource configurations with dependency management

Each terragrunt.hcl includes root.hcl and reads common.hcl to access shared configuration.

### Module Strategy

**Use custom wrapper modules (modules/)** when:
- Managing multiple related resources together with complex interdependencies (e.g., eks-sg creates cluster and node SGs with cross-references)
- Resources have interdependencies that require coordinated creation (e.g., SG rules referencing other SG IDs within same module)
- Combining multiple official modules (e.g., cloudfront = CloudFront + S3 OAC + Bucket Policy, alb = ALB + Target Groups)
- Common logic needs reuse across environments

**Use official modules directly (in terragrunt.hcl)** when:
- Single resource creation (VPC, EC2, S3, Aurora, DynamoDB)
- Environment-specific configuration variations
- 1:1 mapping between terragrunt.hcl and AWS resource
- Resource-specific security groups (defined alongside the resource they protect)

### Directory Structure

```
modules/                    # Custom wrapper modules
  security-groups/          # Creates shared SGs (ALB, Bastion)
  eks-sg/                  # EKS cluster and node SGs with cross-references
  alb/                     # API and WEB ALBs with target groups
  cloudfront/              # CloudFront + S3 OAC + bucket policy
  ecs-iam/                 # ECS task/execution roles + DynamoDB/CloudWatch permissions
  waf/                     # IP Set + Web ACL + CloudFront association

environments/{env}/
  common.hcl              # Environment variables (AWS account, region, CIDR, AMI)
  network/
    vpc/                  # VPC with public/private/database subnets
    security-groups/      # Shared SGs (ALB, Bastion)
  app-api/
    alb/                  # API ALB (uses custom module)
    ecs-cluster/          # ECS cluster (uses official module)
    ecs-sg/               # ECS API security group
    iam/                  # IAM roles for ECS (uses custom module)
  app-web/
    alb/                  # WEB ALB (uses custom module)
    ecs-cluster/          # ECS cluster for web
    ecs-sg/               # ECS WEB security group
    s3-web/              # S3 for static content
  app-scalardb/
    eks-cluster/          # EKS cluster for ScalarDB
    eks-sg/               # EKS cluster and node security groups
  database/
    aurora/              # Aurora MySQL (2 AZ minimum for subnet group)
    aurora-sg/           # Aurora security group
    dynamodb/            # DynamoDB with Point-in-Time Recovery
  edge/
    waf/                 # WAF (must be in us-east-1 for CloudFront)
    lambda-edge/         # Lambda@Edge functions (us-east-1)
    cloudfront/          # CloudFront distribution
  bastion/
    ec2/                 # Bastion host (SSM-only, no SSH)
```

### Deployment Dependencies

Deploy in this order (dependencies are managed via Terragrunt dependency blocks):

1. network/vpc
2. network/security-groups (ALB, Bastion)
3. app-api/ecs-sg, app-web/ecs-sg
4. app-api/alb, app-web/alb
5. app-api/ecs-cluster, app-web/ecs-cluster
6. database/aurora-sg (requires ecs-sg)
7. database/aurora, database/dynamodb
8. app-api/iam (requires DynamoDB ARN)
9. app-web/s3-web
10. app-scalardb/eks-sg (requires ecs-sg)
11. app-scalardb/eks-cluster (requires eks-sg)
12. edge/waf (us-east-1)
13. edge/lambda-edge (us-east-1, optional)
14. edge/cloudfront (requires app-api/alb, app-web/alb, s3-web, waf, lambda-edge)
15. bastion/ec2

Or use `terragrunt run-all apply` to automatically resolve dependencies.

### State Management

- **Backend**: S3 with Terraform 1.10+ native locking (`use_lockfile = true`)
- **No DynamoDB needed**: Uses S3 conditional writes for state locking
- **Bucket requirements**: Must have versioning enabled
- **Bucket naming**: `{project}-{env}-tfstate-{account-id}` (defined in common.hcl)

### Security Groups Architecture

Security groups are organized by scope and managed alongside the resources they protect:

**Shared Security Groups** (`modules/security-groups`, `network/security-groups/`):
- **ALB SG**: Allows HTTP/HTTPS from internet, used by both API and WEB ALBs
- **Bastion SG**: SSM-only, no inbound, outbound only to VPC CIDR

**Resource-Specific Security Groups** (defined in resource directories):
- **ECS API SG** (`app-api/ecs-sg/`): Allows traffic from ALB on ports 80, 3000, 8080, plus Bastion access
- **ECS WEB SG** (`app-web/ecs-sg/`): Allows traffic from ALB on ports 80, 3000, 8080, plus Bastion access
- **Aurora SG** (`database/aurora-sg/`): Allows MySQL (3306) from ECS API, ECS WEB, EKS nodes, and Bastion
- **EKS SGs** (`app-scalardb/eks-sg/`, uses `modules/eks-sg`):
  - **EKS Cluster SG**: Control plane security group with node communication
  - **EKS Node SG**: Worker nodes with access from ECS tasks, control plane, and Bastion

This architecture provides:
- **Separation of concerns**: Each security group is managed with its related resource
- **Clear dependencies**: Security groups reference each other using Terragrunt dependencies
- **Easier maintenance**: Changes to ECS don't affect Aurora or EKS security groups

### IAM Roles for ECS

The ecs-iam custom module creates:
1. **Task Execution Role**: For ECS to pull images, write logs (uses AWS managed policy)
2. **Task Role**: For application access to:
   - DynamoDB (GetItem, PutItem, Query, Scan, etc.)
   - CloudWatch Logs (/aws/ecs/{project}-{env}-*)

### Application Deployment

**Important**: Lambda and ECS applications are NOT deployed via Terraform:
- Use **ecspresso** for ECS task definitions and services
- Use **lambroll** for Lambda functions
- Terraform only manages infrastructure (clusters, IAM roles, security groups, etc.)

### PoC Environment Specifics

- **Single AZ**: All resources except Aurora (requires 2 AZs for subnet group)
- **Bastion**: Private subnet, SSM-only access, no public IP, Amazon Linux 2023
- **Aurora**: Minimal db.t3.medium x1 instance
- **State Locking**: Uses S3 lockfile (no DynamoDB)
- **WAF**: CloudFront WAF in us-east-1, IP restrictions configurable via allowed_ip_addresses in common.hcl
- **CloudFront Caching**: WEB app configurable (PoC uses Managed-CachingDisabled), API always no cache

### Resource Naming Convention

Pattern: `{project}-{env}-{resource-type}-{description}`

Examples:
- VPC: `myapp-poc-vpc`
- Subnets: `myapp-poc-subnet-public-web-1a`, `myapp-poc-subnet-private-app-1a`
- Security Groups: `myapp-poc-sg-alb`, `myapp-poc-sg-ecs`
- ALB: `myapp-poc-alb-api`, `myapp-poc-alb-web`
- ECS Cluster: `myapp-poc-cluster-api`
- S3: `myapp-poc-web-content-{account-id}`

See docs/aws-naming-convention.md for complete rules.

### Important Configuration Values

Update in environments/{env}/common.hcl:
- **aws_account_id**: Your AWS account ID
- **aws_profile**: AWS CLI profile name from ~/.aws/credentials
- **bastion_ami_id**: Amazon Linux 2023 AMI (update regularly)
- **allowed_ip_addresses**: WAF IP restrictions (empty = no restrictions)
- **web_cache_policy_name**: CloudFront cache policy for WEB app

## Connecting to Resources

### Bastion Access (SSM only)

```bash
# Connect via Session Manager (no SSH keys needed)
aws ssm start-session --target {instance-id}
```

### Aurora Access

```bash
# Get Aurora endpoint
cd environments/poc/database/aurora
terragrunt output

# Connect via Bastion
# First connect to Bastion with SSM, then:
mysql -h {aurora-endpoint} -u admin -p
```

## Terraform Module Versions

- vpc/aws: ~> 5.0
- security-group/aws: ~> 5.0
- alb/aws: ~> 9.0
- ecs/aws: ~> 5.0
- rds-aurora/aws: ~> 9.0
- dynamodb-table/aws: ~> 4.0
- s3-bucket/aws: ~> 4.0
- cloudfront/aws: ~> 3.0
- ec2-instance/aws: ~> 5.7

## Common Issues

### Terragrunt Cache Issues

Clear cache: `find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;`

### State Lock Issues

1. Verify Terraform >= 1.10
2. Verify S3 bucket versioning is enabled
3. Verify AWS profile credentials are correct

### Dependency Errors

Use `terragrunt run-all apply` to auto-resolve, or deploy manually in dependency order (see Deployment Dependencies section).

### WAF Must Be in us-east-1

CloudFront requires WAF in us-east-1 region. The waf module uses a separate AWS provider with region = "us-east-1".

## Pre-deployment Setup

Before first deployment:

1. Update environments/{env}/common.hcl with your AWS account ID, profile, and other settings
2. Create S3 state bucket with versioning:
   ```bash
   aws s3api create-bucket --bucket {project}-{env}-tfstate-{account-id} --region ap-northeast-1 --create-bucket-configuration LocationConstraint=ap-northeast-1
   aws s3api put-bucket-versioning --bucket {project}-{env}-tfstate-{account-id} --versioning-configuration Status=Enabled
   ```
3. Update bastion_ami_id to latest Amazon Linux 2023 AMI for your region
