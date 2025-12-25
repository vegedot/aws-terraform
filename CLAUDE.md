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
  eks-access-entries/      # EKS access entries for IAM principals
  alb/                     # API and WEB ALBs with target groups
  cloudfront/              # CloudFront + S3 OAC + bucket policy
  ecs-iam/                 # ECS task/execution roles + DynamoDB/CloudWatch permissions
  waf/                     # IP Set + Web ACL + CloudFront association

environments/{env}/
  common.hcl              # Environment variables (AWS account, region, CIDR, AMI)
  network/
    vpc/                  # VPC with public/private/database subnets
    security-groups/      # Generic policy SGs (HTTP Ingress, HTTPS Ingress, VPC Egress) - use when needed
  app-api/
    alb-sg/               # API ALB security group
    alb/                  # API ALB (uses custom module)
    ecr/                  # ECR repository for Java API images
    ecs-cluster/          # ECS cluster (uses official module)
    ecs-iam/              # ECS IAM roles (uses custom module)
    ecs-sg/               # ECS API security group
  app-web/
    alb-sg/               # WEB ALB security group
    alb/                  # WEB ALB (uses custom module)
    ecr/                  # ECR repository for Node.js WEB images
    ecs-cluster/          # ECS cluster for web
    ecs-iam/              # ECS IAM roles (uses custom module)
    ecs-sg/               # ECS WEB security group
    s3-web/              # S3 for static content
  app-scalardb/
    eks-cluster/          # EKS cluster for ScalarDB
    eks-sg/               # EKS cluster and node security groups
    eks-access-entries/   # EKS access control (Bastion, etc.)
  database/
    aurora/              # Aurora MySQL (2 AZ minimum for subnet group)
    aurora-sg/           # Aurora security group
    dynamodb/            # DynamoDB with Point-in-Time Recovery
  edge/
    waf/                 # WAF (must be in us-east-1 for CloudFront)
    lambda-edge/         # Lambda@Edge functions (us-east-1)
    cloudfront/          # CloudFront distribution
  bastion/
    bastion-sg/           # Bastion security group
    ec2/                 # Bastion host (SSM-only, no SSH)
```

### Deployment Dependencies

Deploy in this order (dependencies are managed via Terragrunt dependency blocks):

1. network/vpc
2. network/security-groups (Generic policies: HTTP Ingress, HTTPS Ingress, VPC Egress)
3. app-api/alb-sg, app-web/alb-sg, bastion/bastion-sg
4. app-api/ecs-sg, app-web/ecs-sg
5. app-api/alb, app-web/alb
6. app-api/ecr, app-web/ecr
7. app-api/ecs-cluster, app-web/ecs-cluster
8. database/aurora-sg (requires ecs-sg, bastion-sg)
9. database/aurora, database/dynamodb
10. app-api/ecs-iam (requires DynamoDB ARN)
11. app-web/ecs-iam
12. app-web/s3-web
13. app-scalardb/eks-sg (requires ecs-sg, bastion-sg)
14. app-scalardb/eks-cluster (requires eks-sg)
15. bastion/ec2 (requires bastion-sg)
16. app-scalardb/eks-access-entries (requires eks-cluster, bastion)
17. edge/waf (us-east-1)
18. edge/lambda-edge (us-east-1, optional)
19. edge/cloudfront (requires app-api/alb, app-web/alb, s3-web, waf, lambda-edge)

Or use `terragrunt run-all apply` to automatically resolve dependencies.

**Note**: EKS access control is managed separately from the cluster itself in `eks-access-entries`. This allows flexible addition/removal of users and roles (e.g., bastion hosts, CI/CD roles) without modifying the EKS cluster configuration. The Bastion's user data includes EKS cluster configuration that will gracefully fail if EKS doesn't exist yet - simply run the `/home/ssm-user/update-kubeconfig.sh` script after both EKS cluster and access entries are deployed.

### State Management

- **Backend**: S3 with Terraform 1.10+ native locking (`use_lockfile = true`)
- **No DynamoDB needed**: Uses S3 conditional writes for state locking
- **Bucket requirements**: Must have versioning enabled
- **Bucket naming**: `{project}-{env}-tfstate-{account-id}` (defined in common.hcl)

### Security Groups Architecture

Security groups are organized by scope and managed alongside the resources they protect:

**Generic Policy Security Groups** (`modules/security-groups`, `network/security-groups/`):
- **HTTP Ingress SG**: Generic policy for HTTP (80) ingress from internet (0.0.0.0/0) - Available for use when needed
- **HTTPS Ingress SG**: Generic policy for HTTPS (443) ingress from internet (0.0.0.0/0) - Available for use when needed
- **VPC Egress SG**: Generic policy for all TCP traffic (0-65535) egress to VPC CIDR - Available for use when needed

**Resource-Specific Security Groups** (defined in resource directories):
- **ALB API SG** (`app-api/alb-sg/`): HTTP/HTTPS from internet for API ALB
- **ALB WEB SG** (`app-web/alb-sg/`): HTTP/HTTPS from internet for WEB ALB
- **Bastion SG** (`bastion/bastion-sg/`): SSM-only, outbound TCP to VPC CIDR
- **ECS API SG** (`app-api/ecs-sg/`): Allows traffic from ALB API SG on ports 80, 3000, 8080, plus Bastion SG access
- **ECS WEB SG** (`app-web/ecs-sg/`): Allows traffic from ALB WEB SG on ports 80, 3000, 8080, plus Bastion SG access
- **Aurora SG** (`database/aurora-sg/`): Allows MySQL (3306) from ECS API SG, ECS WEB SG, EKS nodes, and Bastion SG
- **EKS SGs** (`app-scalardb/eks-sg/`, uses `modules/eks-sg`):
  - **EKS Cluster SG**: Control plane security group with node communication and HTTPS (443) from Bastion SG
  - **EKS Node SG**: Worker nodes with access from ECS tasks, control plane, and HTTPS (443) from Bastion SG

This architecture provides:
- **Separation of concerns**: Each security group is managed with its related resource
- **Clear dependencies**: Security groups reference each other by resource name (ALB SG, Bastion SG, etc.) making intent clear
- **Easier maintenance**: Changes to one resource don't affect others
- **Generic policies available**: Shared HTTPS and VPC internal policies can be used when appropriate

### EKS Access Control Architecture

EKS access control is managed separately from the cluster configuration for flexibility:

**EKS Access Entries** (`app-scalardb/eks-access-entries/`, uses `modules/eks-access-entries`):
- Manages IAM principal access to the EKS cluster
- Currently grants Bastion IAM role admin access via `AmazonEKSClusterAdminPolicy`
- Can be extended to add CI/CD roles, developer roles, etc. without modifying the cluster

Benefits:
- **Flexible access management**: Add/remove users and roles without changing the EKS cluster
- **Independent deployment**: Access entries can be updated independently
- **Scalability**: Easy to manage multiple access entries for different teams/purposes

### IAM Roles for ECS

IAM roles are managed per application for security and flexibility:

**App-API IAM Roles** (`app-api/ecs-iam/`, uses `modules/ecs-iam`):
1. **Task Execution Role**: ECR image pull, CloudWatch Logs write (AWS managed policy)
2. **Task Role**: Application-specific permissions:
   - DynamoDB (GetItem, PutItem, Query, Scan, etc.) - ✅ **enabled**
   - Aurora via Secrets Manager (GetSecretValue) - ✅ **enabled**
   - CloudWatch Logs (/aws/ecs/{project}-{env}-*)
   - AWS X-Ray (PutTraceSegments, PutTelemetryRecords) - ✅ **enabled**

**App-WEB IAM Roles** (`app-web/ecs-iam/`, uses `modules/ecs-iam`):
1. **Task Execution Role**: ECR image pull, CloudWatch Logs write (AWS managed policy)
2. **Task Role**: Application-specific permissions:
   - DynamoDB - ❌ **disabled** (WEB doesn't need database access)
   - Aurora via Secrets Manager - ❌ **disabled** (WEB doesn't need database access)
   - CloudWatch Logs (/aws/ecs/{project}-{env}-*)
   - AWS X-Ray (PutTraceSegments, PutTelemetryRecords) - ✅ **enabled**

Benefits:
- **Principle of Least Privilege**: Each app only has permissions it needs (API has DB access, WEB does not)
- **Independent management**: API and WEB permissions managed separately
- **Flexibility**: Easy to add app-specific permissions (e.g., S3 for WEB, SQS for API)
- **Security**: WEB application has no database access at all, reducing attack surface
- **Observability**: X-Ray tracing enabled for distributed tracing and performance analysis

### Container Image Management (ECR)

**ECR Repositories** are managed per application:

**App-API ECR** (`app-api/ecr/`):
- Repository: `{project}-{env}-api`
- Runtime: Java
- Image scanning: Enabled (vulnerability detection)
- Lifecycle: Keep last 20 images
- Encryption: AES256

**App-WEB ECR** (`app-web/ecr/`):
- Repository: `{project}-{env}-web`
- Runtime: Node.js
- Image scanning: Enabled (vulnerability detection)
- Lifecycle: Keep last 20 images
- Encryption: AES256

**Pushing Images to ECR**:
```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin {account-id}.dkr.ecr.ap-northeast-1.amazonaws.com

# Build and tag image
docker build -t {project}-{env}-api:latest .
docker tag {project}-{env}-api:latest {account-id}.dkr.ecr.ap-northeast-1.amazonaws.com/{project}-{env}-api:latest

# Push to ECR
docker push {account-id}.dkr.ecr.ap-northeast-1.amazonaws.com/{project}-{env}-api:latest
```

### Application Deployment

**Important**: Lambda and ECS applications are NOT deployed via Terraform:
- Use **ecspresso** for ECS task definitions and services
- Use **lambroll** for Lambda functions
- Terraform only manages infrastructure (clusters, IAM roles, security groups, ECR repositories, etc.)

**AWS X-Ray Integration (OpenTelemetry + ADOT Collector)**:
- X-Ray IAM permissions are enabled for both API and WEB applications
- Uses OpenTelemetry SDK in applications + AWS Distro for OpenTelemetry (ADOT) Collector as sidecar
- Add ADOT Collector as a sidecar container in your ECS task definition (via ecspresso)
- Example task definition snippet:
  ```json
  {
    "name": "aws-otel-collector",
    "image": "public.ecr.aws/aws-observability/aws-otel-collector:latest",
    "cpu": 128,
    "memoryReservation": 256,
    "portMappings": [
      {
        "containerPort": 4317,
        "protocol": "tcp"
      },
      {
        "containerPort": 4318,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "AOT_CONFIG_CONTENT",
        "value": "receivers:\n  otlp:\n    protocols:\n      grpc:\n        endpoint: 0.0.0.0:4317\n      http:\n        endpoint: 0.0.0.0:4318\nprocessors:\n  batch:\nexporters:\n  awsxray:\nservice:\n  pipelines:\n    traces:\n      receivers: [otlp]\n      processors: [batch]\n      exporters: [awsxray]"
      }
    ]
  }
  ```
- Configure your application with OpenTelemetry SDK:
  - **Java**: OpenTelemetry Java Agent with OTLP exporter to `localhost:4317` (gRPC)
  - **Node.js**: `@opentelemetry/sdk-node` with OTLP exporter to `localhost:4318` (HTTP)
- ADOT Collector converts OpenTelemetry traces to X-Ray format automatically

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
