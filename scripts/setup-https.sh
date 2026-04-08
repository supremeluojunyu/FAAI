#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "用法: $0 <domain> <email>"
  echo "示例: $0 api.example.com admin@example.com"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$ROOT_DIR/deploy/nginx/moyu-domain.conf.template"
TARGET="/etc/nginx/sites-available/moyu.conf"

echo "[1/5] 生成域名 Nginx 配置..."
sudo sed "s/__DOMAIN__/${DOMAIN}/g" "$TPL" | sudo tee "$TARGET" >/dev/null
sudo ln -sf "$TARGET" /etc/nginx/sites-enabled/moyu.conf
sudo rm -f /etc/nginx/sites-enabled/default

echo "[2/5] 检查并重启 Nginx..."
sudo nginx -t
sudo systemctl restart nginx

echo "[3/5] 申请 Let's Encrypt 证书..."
sudo certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect

echo "[4/5] 验证证书自动续期任务..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
systemctl is-active certbot.timer

echo "[5/5] 完成。"
echo "HTTPS 地址: https://${DOMAIN}/"
