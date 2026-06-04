#!/usr/bin/env bash
# 推送到 GitLab（默认极狐 jihulab.com/supremeluojunyu/FAAI）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ROOT}/config/gitlab.env"
HOST="${GITLAB_HOST:-jihulab.com}"
REPO="${GITLAB_REPO:-supremeluojunyu/FAAI}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a
fi

if [[ -z "${GITLAB_TOKEN:-}" ]]; then
  echo "未找到 GITLAB_TOKEN。请复制 config/gitlab.env.example 为 config/gitlab.env 并填写 Token"
  exit 1
fi

REMOTE_URL="https://oauth2:${GITLAB_TOKEN}@${HOST}/${REPO}.git"
echo "==> 配置 gitlab 远程 (${HOST}/${REPO})"
git remote remove gitlab 2>/dev/null || true
git remote add gitlab "$REMOTE_URL"

TAG="${1:-}"
echo "==> 推送 main"
git push gitlab main

if [[ -n "$TAG" ]]; then
  echo "==> 推送标签 ${TAG}"
  git push gitlab "$TAG"
fi

echo "GitLab 推送完成: https://${HOST}/${REPO}"
