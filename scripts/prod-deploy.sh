#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

echo "[1/8] 安装后端与管理端依赖..."
cd "$ROOT_DIR/backend" && npm install
cd "$ROOT_DIR/admin-web" && npm install

echo "[2/8] 构建后端..."
cd "$ROOT_DIR/backend"
npx prisma db push
npm run build

echo "[3/8] 构建管理端..."
cd "$ROOT_DIR/admin-web"
npm run build

echo "[4/8] 构建 Flutter Web..."
cd "$ROOT_DIR/mobile-app"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
flutter build web

echo "[5/8] 安装 systemd 服务..."
sudo cp "$ROOT_DIR/deploy/systemd/"*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable moyu-backend moyu-admin moyu-mobile-web

echo "[6/8] 停止旧开发进程..."
pkill -f "ts-node-dev --respawn --transpile-only src/server.ts" || true
pkill -f "vite --host 0.0.0.0 --port 5173" || true
pkill -f "python3 -m http.server 8091 --directory /home/golden/FAAI/mobile-app/build/web" || true

echo "[7/8] 启动服务..."
sudo systemctl restart postgresql redis-server
sudo systemctl restart moyu-backend moyu-admin moyu-mobile-web

echo "[8/8] 发布 Nginx 网关..."
sudo cp "$ROOT_DIR/deploy/nginx/moyu.conf" /etc/nginx/sites-available/moyu.conf
sudo ln -sf /etc/nginx/sites-available/moyu.conf /etc/nginx/sites-enabled/moyu.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "部署完成。"
echo "网关: http://192.168.202.142/"
echo "API: http://192.168.202.142/api/v1/models"
echo "Admin: http://192.168.202.142/admin/"
echo "Mobile Web: http://192.168.202.142/mobile/"
