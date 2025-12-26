# ecspresso Integration with Terraform

このディレクトリには、ecspressoを使ってECSサービスとタスク定義をデプロイするためのサンプルファイルが含まれています。

## アーキテクチャ

Terraformとecspressoの役割分担：
- **Terraform**: インフラリソース（VPC, SG, ALB, ECS Cluster, ECR, IAM Rolesなど）
- **ecspresso**: ECS Service と Task Definition のデプロイ

## セットアップ手順

### 1. ecspresso-data モジュールをデプロイ

```bash
cd live/poc/app-api/ecspresso-data
terragrunt apply
```

このモジュールは、ecspressoが必要とする全てのTerraform出力を1つのstateファイルにまとめます。

### 2. Terraform State URLを確認

```bash
# S3バケット名を確認
cd live/poc
cat common.hcl | grep tfstate_bucket

# State URL（ecspresso.ymlで使用）
# s3://{project}-{env}-tfstate-{account-id}/live/poc/app-api/ecspresso-data/terraform.tfstate
```

### 3. ecspresso設定ファイルをアプリリポジトリに配置

アプリケーションのリポジトリに以下のファイルをコピー：

```
your-app-repo/
├── ecspresso.yml           # ecspresso設定
├── ecs-service-def.jsonl   # ECSサービス定義
├── ecs-task-def.jsonl      # ECSタスク定義
├── Dockerfile
└── src/
```

**重要**: `ecspresso.yml` の `url` をあなたの環境に合わせて修正：
```yaml
plugins:
  - name: tfstate
    config:
      url: s3://myapp-poc-tfstate-123456789012/live/poc/app-api/ecspresso-data/terraform.tfstate
      #         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ あなたのバケット名に変更
```

### 4. ecspressoをインストール

```bash
# macOS
brew install ecspresso

# Linux/Windows
# https://github.com/kayac/ecspresso/releases から最新版をダウンロード
```

### 5. CloudWatch Logs ロググループを作成

ecspressoはロググループを自動作成しないため、事前に作成：

```bash
aws logs create-log-group --log-group-name /ecs/myapp-poc-api
aws logs put-retention-policy --log-group-name /ecs/myapp-poc-api --retention-in-days 7
```

### 6. ecspressoでデプロイ

```bash
# 初回デプロイ
ecspresso deploy --config ecspresso.yml

# 設定確認（デプロイせずに差分表示）
ecspresso diff --config ecspresso.yml

# ステータス確認
ecspresso status --config ecspresso.yml

# ログ確認
ecspresso logs --config ecspresso.yml --follow

# サービス削除
ecspresso delete --config ecspresso.yml
```

## CI/CDでの使用例

### GitHub Actions

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions
          aws-region: ap-northeast-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: myapp-poc-api
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

      - name: Install ecspresso
        uses: kayac/ecspresso@v2
        with:
          version: latest

      - name: Deploy to ECS
        run: |
          # Update image tag in task definition
          sed -i "s/:latest/:${{ github.sha }}/g" ecs-task-def.jsonl
          ecspresso deploy --config ecspresso.yml
```

## トラブルシューティング

### エラー: "NoSuchKey: The specified key does not exist"

Terraform stateファイルが見つからない場合：
1. `ecspresso-data` モジュールがデプロイされているか確認
2. S3バケット名とパスが正しいか確認

### エラー: "Template execution error"

Terraform outputsが見つからない場合：
1. `terragrunt output` で出力が存在するか確認
2. output名が `outputs.tf` と一致するか確認

### デプロイが遅い

- `timeout` を延長: `ecspresso deploy --config ecspresso.yml --timeout 20m`
- ALBヘルスチェックの設定を確認

## 参考リンク

- [ecspresso公式ドキュメント](https://github.com/kayac/ecspresso)
- [Terraform tfstate plugin](https://github.com/kayac/ecspresso#tfstate-plugin)
