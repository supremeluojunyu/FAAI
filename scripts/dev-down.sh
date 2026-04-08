#!/usr/bin/env bash
set -euo pipefail

pkill -f "ts-node-dev --respawn --transpile-only src/server.ts" || true
pkill -f "vite --host 0.0.0.0 --port 5173" || true

echo "已停止后端与管理后台开发服务。"
