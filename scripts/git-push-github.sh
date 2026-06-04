#!/usr/bin/env bash
# 使用 config/apk-sync.env 中的 GITHUB_TOKEN（ghp_）经镜像推送，避免直连被重置
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ROOT}/config/apk-sync.env"
REPO="supremeluojunyu/FAAI"
MIRROR_BASE="https://ghproxy.net/https://github.com/${REPO}.git"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "未找到 GITHUB_TOKEN。请写入 ${ENV_FILE}（可参考 config/apk-sync.env.example）"
  echo "或执行: gh auth login && gh auth token > ${ENV_FILE}"
  exit 1
fi

echo "==> 配置 origin（HTTPS + 镜像 + PAT）"
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@${MIRROR_BASE#https://}"

TAG="${1:-}"
echo "==> 推送 main"
git push origin main

if [[ -n "$TAG" ]]; then
  echo "==> 推送标签 ${TAG}"
  git push origin "$TAG"
elif git rev-parse v0.0.6 >/dev/null 2>&1; then
  git push origin v0.0.6 2>/dev/null || true
fi

echo "推送完成。等待 GitHub Actions 构建 APK 后执行: node scripts/sync-apk-download.mjs"
