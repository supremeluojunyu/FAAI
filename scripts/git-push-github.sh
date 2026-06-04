#!/usr/bin/env bash
# 在 HTTPS 被重置的网络环境下，通过 SSH 推送 GitHub
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REMOTE_SSH="git@github.com:supremeluojunyu/FAAI.git"
PUBKEY_FILE="${HOME}/.ssh/id_ed25519.pub"

echo "==> 配置 origin 为 SSH"
git remote set-url origin "$REMOTE_SSH"

if [[ ! -f "$PUBKEY_FILE" ]]; then
  echo "未找到 SSH 公钥，正在生成..."
  ssh-keygen -t ed25519 -N "" -f "${HOME}/.ssh/id_ed25519"
fi

echo ""
echo "请将以下公钥添加到 GitHub: https://github.com/settings/ssh/new"
echo "名称可填: golden120"
echo "----------------------------------------"
cat "$PUBKEY_FILE"
echo "----------------------------------------"
echo ""

echo "==> 测试 SSH 连接"
if ssh -o BatchMode=yes -T git@github.com 2>&1 | grep -qi "successfully authenticated"; then
  echo "SSH 已就绪，开始推送..."
  git push origin main
  if git rev-parse v0.0.5 >/dev/null 2>&1; then
    git push origin v0.0.5
  fi
  echo "推送完成。等待 GitHub Actions 构建 APK 后执行: node scripts/sync-apk-download.mjs"
else
  echo "SSH 尚未授权。添加公钥后重新运行: bash scripts/git-push-github.sh"
  exit 1
fi
