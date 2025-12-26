#!/bin/bash
set -e

# CloudShell環境セットアップスクリプト
# EKS (ScalarDB), ECR (Docker), ECS (ecspresso) に必要なツールをインストール

echo "=== CloudShell環境セットアップ開始 ==="

# 永続的ストレージのディレクトリ設定
BIN_DIR="$HOME/bin"
TEMP_DIR="$HOME/tmp"

# ディレクトリ作成
mkdir -p "$BIN_DIR"
mkdir -p "$TEMP_DIR"

# PATHに追加（.bashrcに未追加の場合のみ）
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    echo "PATHを.bashrcに追加しました"
fi

# 現在のセッションでもPATHを設定
export PATH="$BIN_DIR:$PATH"

# バージョン設定
KUBECTL_VERSION="v1.31.0"
HELM_VERSION="v3.16.3"
ECSPRESSO_VERSION="v2.4.3"
DOCKER_VERSION="27.4.1"

echo ""
echo "=== 1. git の確認 ==="
if command -v git &> /dev/null; then
    echo "git は既にインストール済みです: $(git --version)"
else
    echo "エラー: git がインストールされていません"
    exit 1
fi

echo ""
echo "=== 2. kubectl のインストール ==="
if command -v kubectl &> /dev/null; then
    echo "kubectl は既にインストール済みです: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    echo "kubectl ${KUBECTL_VERSION} をインストール中..."
    curl -sLo "$TEMP_DIR/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x "$TEMP_DIR/kubectl"
    mv "$TEMP_DIR/kubectl" "$BIN_DIR/kubectl"
    echo "kubectl インストール完了: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

echo ""
echo "=== 3. helm のインストール ==="
if command -v helm &> /dev/null; then
    echo "helm は既にインストール済みです: $(helm version --short)"
else
    echo "helm ${HELM_VERSION} をインストール中..."
    curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o "$TEMP_DIR/helm.tar.gz"
    tar -xzf "$TEMP_DIR/helm.tar.gz" -C "$TEMP_DIR"
    mv "$TEMP_DIR/linux-amd64/helm" "$BIN_DIR/helm"
    chmod +x "$BIN_DIR/helm"
    rm -rf "$TEMP_DIR/helm.tar.gz" "$TEMP_DIR/linux-amd64"
    echo "helm インストール完了: $(helm version --short)"
fi

echo ""
echo "=== 4. Docker CLI のインストール ==="
if command -v docker &> /dev/null && docker --version | grep -q "$DOCKER_VERSION"; then
    echo "docker は既にインストール済みです: $(docker --version)"
else
    echo "Docker CLI ${DOCKER_VERSION} をインストール中..."
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o "$TEMP_DIR/docker.tgz"
    tar -xzf "$TEMP_DIR/docker.tgz" -C "$TEMP_DIR"
    mv "$TEMP_DIR/docker/docker" "$BIN_DIR/docker"
    chmod +x "$BIN_DIR/docker"
    rm -rf "$TEMP_DIR/docker.tgz" "$TEMP_DIR/docker"
    echo "Docker CLI インストール完了: $(docker --version)"
    echo ""
    echo "注意: CloudShellではDocker daemonが動作していないため、docker buildはできません。"
    echo "ECRイメージのビルドにはローカル環境またはEC2/CodeBuildを使用してください。"
fi

echo ""
echo "=== 5. ecspresso のインストール ==="
if command -v ecspresso &> /dev/null; then
    echo "ecspresso は既にインストール済みです: $(ecspresso version)"
else
    echo "ecspresso ${ECSPRESSO_VERSION} をインストール中..."
    curl -sL "https://github.com/kayac/ecspresso/releases/download/${ECSPRESSO_VERSION}/ecspresso_${ECSPRESSO_VERSION}_linux_amd64.tar.gz" -o "$TEMP_DIR/ecspresso.tar.gz"
    tar -xzf "$TEMP_DIR/ecspresso.tar.gz" -C "$TEMP_DIR"
    mv "$TEMP_DIR/ecspresso" "$BIN_DIR/ecspresso"
    chmod +x "$BIN_DIR/ecspresso"
    rm -f "$TEMP_DIR/ecspresso.tar.gz"
    echo "ecspresso インストール完了: $(ecspresso version)"
fi

echo ""
echo "=== セットアップ完了 ==="
echo "以下のツールがインストールされました:"
echo ""
echo "git:       $(git --version)"
echo "kubectl:   $(kubectl version --client --short 2>/dev/null || kubectl version --client | head -n1)"
echo "helm:      $(helm version --short)"
echo "docker:    $(docker --version)"
echo "ecspresso: $(ecspresso version)"
echo ""
echo "インストール先: $BIN_DIR"
echo ""
echo "新しいターミナルセッションでは自動的にPATHが設定されます。"
echo "現在のセッションで使用する場合は以下を実行してください:"
echo "  source ~/.bashrc"
echo ""

