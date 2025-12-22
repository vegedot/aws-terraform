# AWS リソース命名規則

## 目的

AWSリソースの命名規則を定義したガイドラインである。

## 基本原則

1. **一貫性**: すべてのリソースで同じ命名パターンを使用
2. **可読性**: 名前を見ただけで用途が分かる
3. **環境識別**: 環境（poc/dev/production）を明確に識別
4. **AWS制約**: AWSの命名制約に従う
5. **自動化対応**: Terraformでの管理を前提とした命名

## 命名パターン

### 基本フォーマット

```
{project}-{environment}-{resource-type}-{description}
```

**例**: `myapp-poc-vpc-main`

### 要素の定義

| 要素 | 説明 | 例 | 別名 |
|------|------|-----|------|
| `project` | プロジェクト名（小文字、短縮形可） | `myapp` | System |
| `environment` | 環境名 | `poc`, `dev`, `prod`, `stg`, `proddr` | Env |
| `resource-type` | リソースタイプ（省略形） | `vpc`, `sg`, `alb`, `ecs` | - |
| `description` | リソースの説明・役割 | `api`, `web`, `db`, `main` | Usage |

### 環境名

| 環境 | 識別子 | 用途 |
|------|--------|------|
| Production | `prod` | 本番環境 |
| Production DR | `proddr` | 本番DR（災害復旧）環境 |
| Staging | `stg` | ステージング環境 |
| Staging DR | `stgdr` | ステージングDR環境 |
| Development | `dev` | 開発環境 |
| PoC | `poc` | 概念実証環境 |

**注意**:
- 複数環境で共有するリソースには、**最も重要度の高い環境名**を使用する
- 例: 本番(prod)と開発(dev)で共有 → `prod` を使用

## リソースタイプ別命名規則

### 1. ネットワーク

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| VPC | `{project}-{env}-vpc` | `myapp-poc-vpc` | - |
| Subnet | `{project}-{env}-subnet-{subnet-type}-{usage}-{az-id}` | `myapp-poc-subnet-public-web-1a`<br>`myapp-poc-subnet-private-app-1a`<br>`myapp-poc-subnet-private-db-1a` | subnet-type: `public`, `private`<br>usage: `web`, `app`, `db`<br>az-id: `1a`, `1c` など |
| Internet Gateway | `{project}-{env}-igw` | `myapp-poc-igw` | - |
| NAT Gateway | `{project}-{env}-nat-{az}` | `myapp-poc-nat-1a` | - |
| Route Table | `{project}-{env}-rtb-{type}` | `myapp-poc-rtb-public`<br>`myapp-poc-rtb-private` | - |

### 2. セキュリティ

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| Security Group | `{project}-{env}-sg-{purpose}` | `myapp-poc-sg-alb`<br>`myapp-poc-sg-ecs`<br>`myapp-poc-sg-rds`<br>`myapp-poc-sg-bastion` | - |
| IAM Role | `{project}-{env}-role-{service}` | `myapp-poc-role-ecs-task`<br>`myapp-poc-role-ecs-execution`<br>`myapp-poc-role-bastion` | - |
| IAM Policy | `{project}-{env}-policy-{purpose}` | `myapp-poc-policy-s3-access` | - |

### 3. コンピューティング

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| EC2 Instance | `{project}-{env}-ec2-{purpose}` | `myapp-poc-ec2-bastion` | - |
| ECS Cluster | `{project}-{env}-cluster-{purpose}` | `myapp-poc-cluster-api`<br>`myapp-poc-cluster-web` | - |
| ECS Service | `{project}-{env}-{app-name}` | `myapp-poc-api`<br>`myapp-poc-web` | - |
| ECS Task Definition | `{project}-{env}-task-{app-name}` | `myapp-poc-task-api`<br>`myapp-poc-task-web` | - |

### 4. ロードバランサー

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| ALB/NLB | `{project}-{env}-{type}-{purpose}` | `myapp-poc-alb-api`<br>`myapp-poc-alb-web` | - |
| Target Group | `{project}-{env}-tg-{purpose}` | `myapp-poc-tg-api`<br>`myapp-poc-tg-web` | - |

### 5. データベース

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| RDS/Aurora | `{project}-{env}-{db-engine}-{purpose}` | `myapp-poc-aurora-main`<br>`myapp-dev-mysql-app` | - |
| DB Subnet Group | `{project}-{env}-dbsubnet` | `myapp-poc-dbsubnet` | - |
| DB Parameter Group | `{project}-{env}-{db-engine}-params` | `myapp-poc-aurora-params` | - |
| DynamoDB Table | `{project}-{env}-dynamodb-{purpose}` | `myapp-poc-dynamodb-main`<br>`myapp-dev-dynamodb-sessions` | - |

### 6. ストレージ

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| S3 Bucket | `{project}-{env}-{purpose}-{account-id}` | `myapp-prod-web-content-123456789012`<br>`myapp-prod-logs-123456789012`<br>`myapp-prod-tfstate-123456789012` | グローバルで一意 |
| EBS Volume | `{project}-{env}-ebs-{instance}-{purpose}` | `myapp-poc-ebs-bastion-data` | - |

### 7. CDN・キャッシュ・WAF

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| CloudFront Distribution | Nameタグで識別: `{project}-{env}-cdn` | `myapp-poc-cdn` | - |
| ElastiCache | `{project}-{env}-{engine}-{purpose}` | `myapp-poc-redis-session` | - |
| WAF Web ACL | `{project}-{env}-waf-{purpose}` | `myapp-poc-waf-cloudfront` | CloudFrontはus-east-1 |
| WAF IP Set | `{project}-{env}-waf-ipset` | `myapp-poc-waf-ipset` | - |

### 8. モニタリング・ログ

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| CloudWatch Log Group | `/aws/{service}/{project}-{env}-{purpose}` | `/aws/ecs/myapp-poc-api`<br>`/aws/lambda/myapp-poc-processor` | - |
| CloudWatch Alarm | `{project}-{env}-alarm-{resource}-{metric}` | `myapp-poc-alarm-ecs-cpu-high` | - |

### 9. その他

| リソースタイプ | 命名パターン | 例 | 備考 |
|--------------|------------|-----|------|
| Lambda Function | `{project}-{env}-{purpose}` | `myapp-poc-image-processor` | - |
| SNS Topic | `{project}-{env}-topic-{purpose}` | `myapp-poc-topic-alerts` | - |
| SQS Queue | `{project}-{env}-queue-{purpose}` | `myapp-poc-queue-tasks` | - |

## タグ規則

すべてのリソースに以下のタグを付与する：

### 必須タグ

```hcl
tags = {
  Project     = "myapp"
  Environment = "poc"  # poc/dev/prod
  ManagedBy   = "Terraform"
  Name        = "{リソース名}"
}
```

#### Terragruntでの実装方法

環境ごとの共通タグは`common.hcl`で定義し、各リソースに渡す：

**common.hcl**:
```hcl
locals {
  environment  = "poc"
  project_name = "myapp"

  common_tags = {
    Project     = "myapp"
    Environment = "poc"
    ManagedBy   = "Terraform"
  }
}
```

**各リソースのterragrunt.hcl**:
```hcl
locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common_tags  = local.common_vars.locals.common_tags
  project_name = local.common_vars.locals.project_name
  environment  = local.common_vars.locals.environment
}

# VPCの例（Nameタグ自動生成）
inputs = {
  name = "${local.project_name}-${local.environment}-vpc"
  tags = local.common_tags  # nameからNameタグが自動生成される
}

# ALBの例（Nameタグ明示指定が必要）
inputs = {
  name = "${local.project_name}-${local.environment}-alb-api"
  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-${local.environment}-alb-api"
    }
  )
}
```

Project、Environment、ManagedByは`common_tags`から自動的に付与され、各リソースでNameタグのみを追加する。

#### Terraform公式モジュールのNameタグ自動生成

terraform-aws-modulesの公式モジュールは、`name`パラメータからのNameタグ自動生成動作が異なる。

**✅ 自動生成するモジュール** (`name`パラメータから自動的にNameタグを作成):

| モジュール | タグ設定 |
|-----------|---------|
| VPC | `tags = local.common_tags` のみでOK |
| EC2 Instance | `tags = local.common_tags` のみでOK |
| Security Group | `tags = local.common_tags` のみでOK |

**❌ 自動生成しないモジュール** (明示的なNameタグ指定が必要):

| モジュール | タグ設定 |
|-----------|---------|
| ALB | `tags = merge(local.common_tags, { Name = "..." })` |
| S3 Bucket | `tags = merge(local.common_tags, { Name = "..." })` |
| RDS Aurora | `tags = merge(local.common_tags, { Name = "..." })` |
| ECS Cluster | `tags = merge(local.common_tags, { Name = "..." })` |
| ECS Service | `tags = merge(local.common_tags, { Name = "..." })` |
| CloudFront | `tags = merge(local.common_tags, { Name = "..." })` |

実装時は各モジュールのソースコードでタグ処理を確認すること。

### 運用制御タグ

自動化処理やリソース管理のための制御タグ。必要に応じて追加する。

```hcl
tags = {
  # 必須タグ
  Project     = "myapp"
  Environment = "poc"
  ManagedBy   = "Terraform"
  Name        = "{リソース名}"

  # 運用制御タグ（必要に応じて追加）
  BackupSelection = "daily"      # AWS Backupでのバックアップ対象識別
  SsmPatchTarget  = "group-a"    # Systems Managerパッチグループ
}
```

**運用制御タグの用途例**:

| タグ | 用途 | 値の例 |
|------|------|--------|
| `BackupSelection` | AWS Backup計画の選択 | `daily`, `weekly`, `none` |
| `SsmPatchTarget` | パッチ適用グループ | `group-a`, `group-b`, `critical` |
| `DataClassification` | データ分類 | `public`, `internal`, `confidential` |

## 参考資料

- [AWS Tagging Best Practices](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html)
- [AWS Service Naming Conventions](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)
