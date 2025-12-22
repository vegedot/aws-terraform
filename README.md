# AWS Infrastructure with Terragrunt + Terraform

Terragrunt と Terraform を使用した AWS PoC 環境のインフラストラクチャコード。

## ディレクトリ構造

```
aws-terraform/
├── root.hcl              # 全環境共通設定
├── modules/              # カスタムモジュール
│   ├── security-groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   ├── cloudfront/
│   ├── ecs-iam/
│   └── waf/
└── environments/         # 環境別設定
    ├── poc/              # PoC環境
    │   ├── common.hcl    # 環境固有変数
    │   ├── terragrunt.hcl
    │   ├── network/      # VPC、セキュリティグループ
    │   ├── app-api/      # APIアプリケーション
    │   │   ├── alb/
    │   │   │   └── terragrunt.hcl
    │   │   ├── ecs-cluster/
    │   │   │   └── terragrunt.hcl
    │   │   └── iam/
    │   │       └── terragrunt.hcl
    │   ├── app-web/      # WEBアプリケーション
    │   │   ├── alb/
    │   │   │   └── terragrunt.hcl
    │   │   ├── ecs-cluster/
    │   │   │   └── terragrunt.hcl
    │   │   └── s3-web/
    │   │       └── terragrunt.hcl
    │   ├── app-scalardb/ # ScalarDB Cluster (EKS)
    │   │   ├── eks-cluster/
    │   │   └── node-group/
    │   ├── database/     # データベース
    │   │   ├── aurora/
    │   │   └── dynamodb/
    │   ├── edge/         # エッジ・CDN層
    │   │   ├── waf/
    │   │   ├── lambda-edge/
    │   │   └── cloudfront/
    │   └── bastion/      # 踏み台サーバー
    ├── dev/              # Development環境
    └── production/       # Production環境
```

### モジュール構成の方針

構築するAWSリソースがterraform-aws-modules公式モジュールに存在し活用できる場合は、公式モジュールを使用する。

公式モジュールを**直接呼び出す**か、**カスタムWrapperモジュール**を作成するかは以下を判断基準とする。

#### Wrapper Module作成が適切なケース (modules/)

以下のいずれかに該当する場合、`modules/`配下にカスタムモジュールを作成する：

- ✅ **複数の関連リソースを一括管理**
  - 例: security-groups（ALB/ECS/Aurora/Bastion用の4つのSG）

- ✅ **リソース間に相互依存関係がある**
  - 例: セキュリティグループルールでSG IDを相互参照

- ✅ **環境間で共通のロジックを再利用**
  - 例: すべての環境でAPI/WEB用ALBが必要

- ✅ **複数の公式モジュールを組み合わせる**
  - 例: cloudfront（CloudFront + S3 OAC + S3 Bucket Policy）

- ✅ **カスタムロジックやリソース後処理が必要**
  - 例: ALBとTarget Groupの命名規則統一

**実装例**:
```hcl
# modules/security-groups/main.tf
module "alb_sg" { ... }
module "ecs_sg" { ... }
module "aurora_sg" { ... }
module "bastion_sg" { ... }

# 相互参照ルール
resource "aws_security_group_rule" "bastion_to_ecs" {
  source_security_group_id = module.bastion_sg.security_group_id
  security_group_id        = module.ecs_sg.security_group_id
}
```

#### 直接呼び出しが適切なケース (terragrunt.hcl)

以下のいずれかに該当する場合、`terragrunt.hcl`から公式モジュールを直接参照する：

- ✅ **単一リソースのみを作成**
  - 例: VPC、EC2インスタンス、S3バケット

- ✅ **環境ごとに大きく異なる設定**
  - 例: PoC/Dev/Prodで異なるインスタンスタイプ

- ✅ **公式モジュールをそのまま使える**
  - 例: terraform-aws-modules/vpc/aws

- ✅ **1対1の単純なマッピング**
  - 1つのterragrunt.hcl = 1つのリソース

**実装例**:
```hcl
# environments/poc/network/vpc/terragrunt.hcl
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=6.5.1"
}
```

#### 判断フロー

```
新しいリソースを追加する場合
    ↓
1つのリソースで完結？
    ├─ YES → terragrunt.hclで直接呼び出し
    └─ NO  → 次の質問へ
         ↓
環境間で共通のロジック？
    ├─ YES → modules/でWrapper作成
    └─ NO  → terragrunt.hclで直接呼び出し
         ↓
複数リソースの組み合わせ？
    ├─ YES → modules/でWrapper作成
    └─ NO  → terragrunt.hclで直接呼び出し
```

#### 実装例

| 実装方法 | リソース | 理由 |
|---------|---------|------|
| **Wrapper作成** | security-groups | 4つのSG + 相互参照ルール |
| **Wrapper作成** | alb | API/WEB用の2つのALB + TG |
| **Wrapper作成** | cloudfront | CloudFront + S3 OAC + Bucket Policy |
| **Wrapper作成** | ecs-iam | ECS Task/Execution Role + DynamoDB/CloudWatch権限 |
| **直接呼び出し** | VPC | 単一リソース、環境固有設定 |
| **直接呼び出し** | EC2 | 単一リソース、環境固有設定 |
| **直接呼び出し** | S3 | 単一リソース、環境固有設定 |
| **直接呼び出し** | ECS | 単一リソース、環境固有設定 |
| **直接呼び出し** | Aurora | 単一リソース、環境固有設定 |
| **直接呼び出し** | DynamoDB | 単一リソース、環境固有設定 |
| **Wrapper作成** | waf | IP Set + Web ACL + CloudFront関連付け |

#### environments/ の構成

論理グループで整理し、terraform-aws-modulesまたはカスタムモジュールを参照。環境固有の値はcommon.hclで管理とする。

- **network/**: VPC、Security Groups (ALB、ECS、Aurora、Bastion、EKS)
- **app-api/**: API ALB、ECS Cluster、IAM Roles
- **app-web/**: WEB ALB、ECS Cluster、S3
- **app-scalardb/**: EKS Cluster、Node Group (ScalarDB Cluster用)
- **database/**: Aurora、DynamoDB
- **edge/**: WAF、Lambda@Edge、CloudFront
- **bastion/**: EC2

## 前提条件

- Terraform 1.14.3
- Terragrunt 0.63.6
- AWS CLI 設定済み
- 適切な AWS 認証情報（`~/.aws/credentials`にプロファイル設定）
- 環境ごとのAWSアカウントIDとプロファイル名を`common.hcl`に設定

## デプロイツール

このプロジェクトでは、リソースの種類に応じて適切なデプロイツールを使用する。

- **Terraform/Terragrunt**: インフラストラクチャリソース（VPC、ALB、RDS、S3、ECS Cluster、IAM Rolesなど）
- **ecspresso**: ECS タスク定義とサービスのデプロイ
- **lambroll**: Lambda 関数のデプロイ

**注意**:
- Lambda と ECS のアプリケーションデプロイは、ecspresso と lambroll を使用するため、Terraform では定義しない
- Terraform では ECS クラスター、IAM ロール、セキュリティグループなどのインフラ基盤を管理
- ECS TaskはTerraformで作成したIAMロールを使用してDynamoDB、Auroraにアクセス可能

## PoC環境の構成

- **VPC**: 単一AZ構成でコスト削減（Aurora除く）
- **Bastion**: プライベートサブネット配置、SSM接続のみ（SSH無効）、Amazon Linux 2023使用
- **セキュリティ**: Bastion SGはVPC内通信のみ許可、外部接続なし
- **Aurora**: 最小インスタンス（db.t3.medium x1）、Subnet Groupは2AZ必須
- **DynamoDB**: オンデマンド課金、Point-in-Time Recovery有効
- **ECS**: Fargate、最小タスク数
- **WAF**: CloudFront用、us-east-1リージョンで作成、IP制限は環境ごとに設定可能
- **CloudFrontキャッシュ**: WEBアプリは環境ごとに設定可能、API/S3は固定
  - PoC/開発: WEBキャッシュ無効（`Managed-CachingDisabled`）
  - 本番: WEBキャッシュ有効（`Managed-CachingOptimized`）
  - API: 常にキャッシュ無効
  - S3静的コンテンツ: 常にキャッシュ有効
- **State Lock**: Terraform 1.10+ の `use_lockfile` 機能でDynamoDB不要（バージョニングのみ必要）
- **環境設定**: AWSアカウントID、プロファイル、tfstateバケット名は `environments/{env}/common.hcl` で管理
- **AMI管理**: Bastion AMI IDは `environments/{env}/common.hcl` で管理、定期的に更新すること
- **IP制限**: `allowed_ip_addresses`が空の場合は制限なし（PoC/開発）、IPを指定すると制限あり（本番）

## バージョン情報

- **Terraform**: 1.14.3
- **Terragrunt**: 0.63.6
- **terraform-aws-modules**: 各モジュールの最新安定版を使用
  - vpc/aws: ~> 6.5
  - security-group/aws: ~> 5.3
  - alb/aws: ~> 10.4
  - ecs/aws: ~> 6.7
  - rds-aurora/aws: ~> 10.0
  - dynamodb-table/aws: ~> 5.4
  - s3-bucket/aws: ~> 5.9
  - cloudfront/aws: ~> 6.0
  - ec2-instance/aws: ~> 6.1
  - eks/aws: ~> 21.10
  - lambda/aws: ~> 8.1

## デプロイ手順

### 1. 環境設定の更新

`environments/poc/common.hcl`で環境固有の値を設定：

```hcl
locals {
  environment = "poc"

  # AWS Configuration
  aws_region     = "ap-northeast-1"
  aws_profile    = "default"  # ~/.aws/credentialsのプロファイル名
  aws_account_id = "123456789012"  # 実際のAWSアカウントID

  # Terraform State S3 Bucket
  tfstate_bucket = "${local.project_name}-${local.environment}-tfstate-${local.aws_account_id}"
  # ...
}
```

### 2. S3バケットの作成

Terragrunt のリモートステート用 S3 バケットを作成。

**Terraform 1.10+** の `use_lockfile = true` により **DynamoDB不要**で State Lock が可能です。これはS3の条件付き書き込み機能を使用します。

#### S3バケット作成手順

```bash
# common.hclに設定した値を使用
PROJECT_NAME="myapp"  # プロジェクト名
AWS_ACCOUNT_ID="123456789012"  # 実際の値に置き換え
AWS_PROFILE="default"  # 実際の値に置き換え
ENVIRONMENT="poc"  # 環境名（poc/dev/prod）

# 1. S3バケットを作成
aws s3api create-bucket \
  --bucket ${PROJECT_NAME}-${ENVIRONMENT}-tfstate-${AWS_ACCOUNT_ID} \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1 \
  --profile ${AWS_PROFILE}

# 2. バケットのバージョニングを有効化（必須）
aws s3api put-bucket-versioning \
  --bucket ${PROJECT_NAME}-${ENVIRONMENT}-tfstate-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled \
  --profile ${AWS_PROFILE}

# 3. バケットの暗号化を有効化（推奨）
aws s3api put-bucket-encryption \
  --bucket ${PROJECT_NAME}-${ENVIRONMENT}-tfstate-${AWS_ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile ${AWS_PROFILE}
```

**確認**:
```bash
# バケット設定を確認
aws s3api get-bucket-versioning --bucket ${PROJECT_NAME}-${ENVIRONMENT}-tfstate-${AWS_ACCOUNT_ID} --profile ${AWS_PROFILE}
aws s3api get-bucket-encryption --bucket ${PROJECT_NAME}-${ENVIRONMENT}-tfstate-${AWS_ACCOUNT_ID} --profile ${AWS_PROFILE}
```

### 3. PoC環境全体のデプロイ

```bash
cd environments/poc

# 全リソースを一括デプロイ
terragrunt run-all apply
```

### 4. 個別リソースのデプロイ

依存関係を考慮した推奨デプロイ順序：

```bash
cd environments/poc

# 1. Network - VPC
cd network/vpc && terragrunt apply && cd ../..

# 2. Network - Security Groups
cd network/security-groups && terragrunt apply && cd ../..

# 3. App-API - ALB
cd app-api/alb && terragrunt apply && cd ../..

# 4. App-API - ECS Cluster
cd app-api/ecs-cluster && terragrunt apply && cd ../..

# 5. App-Web - ALB
cd app-web/alb && terragrunt apply && cd ../..

# 6. App-Web - ECS Cluster
cd app-web/ecs-cluster && terragrunt apply && cd ../..

# 7. App-Web - S3
cd app-web/s3-web && terragrunt apply && cd ../..

# 8. Database - Aurora
cd database/aurora && terragrunt apply && cd ../..

# 9. Database - DynamoDB
cd database/dynamodb && terragrunt apply && cd ../..

# 10. App-API - IAM Roles
cd app-api/iam && terragrunt apply && cd ../..

# 11. App-ScalarDB - EKS Cluster
cd app-scalardb/eks-cluster && terragrunt apply && cd ../..

# 12. App-ScalarDB - Node Group
cd app-scalardb/node-group && terragrunt apply && cd ../..

# 13. Edge - WAF (us-east-1)
cd edge/waf && terragrunt apply && cd ../..

# 14. Edge - Lambda@Edge (us-east-1、オプション)
cd edge/lambda-edge && terragrunt apply && cd ../..

# 15. Edge - CloudFront
cd edge/cloudfront && terragrunt apply && cd ../..

# 16. Bastion - EC2
cd bastion/ec2 && terragrunt apply && cd ../..
```

### 5. 論理グループ単位でのデプロイ

依存関係を考慮した推奨デプロイ順序：

```bash
cd environments/poc

# 1. ネットワーク基盤
cd network && terragrunt run-all apply && cd ..

# 2. APIアプリケーション（ALB、ECS Cluster）
cd app-api && terragrunt run-all apply && cd ..

# 3. WEBアプリケーション（ALB、ECS Cluster、S3）
cd app-web && terragrunt run-all apply && cd ..

# 4. データベース（Aurora、DynamoDB）
cd database && terragrunt run-all apply && cd ..

# 5. App-API IAM（DynamoDB依存）
cd app-api/iam && terragrunt apply && cd ..

# 6. ScalarDBクラスター（EKS、Node Group）
cd app-scalardb && terragrunt run-all apply && cd ..

# 7. エッジ・CDN層（WAF、Lambda@Edge、CloudFront）
cd edge && terragrunt run-all apply && cd ..

# 8. 踏み台サーバー
cd bastion && terragrunt run-all apply && cd ..
```

**注意**: `app-api/iam`はDynamoDB ARNに依存するため、`database`グループの後に個別デプロイが必要です。

## アクセス方法

### Bastion ホストへのアクセス

BastionはSSM Session Manager経由でのみアクセス可能（SSH接続は無効）。プライベートサブネットに配置され、パブリックIPは持たない。

```bash
# Session Manager経由で接続
aws ssm start-session --target {instance-id}
```

### Auroraへの接続

Bastion経由でAuroraに接続：

```bash
# エンドポイント取得
cd environments/poc/database/aurora
terragrunt output

# Bastion経由で接続
mysql -h {aurora-endpoint} -u admin -p
```

## トラブルシューティング

### Terragrunt キャッシュのクリア

**Bash / Linux / macOS:**
```bash
find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
```

**PowerShell / Windows:**
```powershell
Get-ChildItem -Path . -Filter ".terragrunt-cache" -Recurse -Directory | Remove-Item -Recurse -Force
```

### 依存関係エラー
依存関係エラーが発生した場合は個別に順序を守ってデプロイ

### バージョン確認

```bash
terraform version    # Terraform v1.14.3
terragrunt --version # terragrunt version v0.63.6
```

### Terragrunt 0.63.6 の既知の問題

- **include blocks**: `root.hcl` を `find_in_parent_folders()` で正しく参照できることを確認
- **dependency blocks**: 循環参照に注意
- **モジュールソース**: `tfr://` プレフィックス使用時はバージョン指定が必須

### State Lock のトラブルシューティング

**`use_lockfile` が動作しない場合**:
1. Terraform 1.10+ であることを確認
2. S3バケットのバージョニングが有効化されていることを確認
3. AWS認証情報（プロファイル）が正しいことを確認

**確認コマンド**:
```bash
terraform version  # 1.10+ であることを確認
aws s3api get-bucket-versioning --bucket ${BUCKET_NAME} --profile ${AWS_PROFILE}
```

**DynamoDBからの移行**:
1. `root.hcl` から `dynamodb_table` を削除
2. `use_lockfile = true` を追加
3. 既存ロックが残っていないか確認して再実行

### terraform-aws-modules のバージョン更新

最新バージョンは [Terraform Registry](https://registry.terraform.io/browse/modules?provider=aws) で確認。バージョン更新時は各 `terragrunt.hcl` の `source` パラメータを変更。

## ドキュメント

- [AWS リソース命名規則](docs/aws-naming-convention.md)

## 参考

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform 1.10 Release Notes - S3 State Locking](https://github.com/hashicorp/terraform/releases/tag/v1.10.0)
- [Terraform 1.14 Release Notes](https://github.com/hashicorp/terraform/releases)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt 0.63.6 Release](https://github.com/gruntwork-io/terragrunt/releases)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Terraform Registry - AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS S3 Object Lock Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
