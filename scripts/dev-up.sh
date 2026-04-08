#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/5] 启动 PostgreSQL / Redis..."
sudo systemctl start postgresql redis-server

echo "[2/5] 确认后端环境文件..."
if [ ! -f "$ROOT_DIR/backend/.env" ]; then
  cp "$ROOT_DIR/backend/.env.example" "$ROOT_DIR/backend/.env"
fi

echo "[3/5] 同步 Prisma Schema..."
cd "$ROOT_DIR/backend"
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
npx prisma db push >/dev/null

echo "[4/5] 启动后端..."
nohup npm run dev > "$ROOT_DIR/.backend.log" 2>&1 &

echo "[5/5] 启动管理后台..."
cd "$ROOT_DIR/admin-web"
nohup npm run dev -- --host 0.0.0.0 --port 5173 > "$ROOT_DIR/.admin.log" 2>&1 &

echo "完成。"
echo "后端: http://192.168.202.142:3000"
echo "管理端: http://192.168.202.142:5173"
