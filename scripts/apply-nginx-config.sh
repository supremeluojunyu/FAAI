#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sudo sed "s#__ROOT__#${ROOT_DIR}#g" "$ROOT_DIR/deploy/nginx/moyu.conf" | sudo tee /etc/nginx/sites-available/moyu.conf >/dev/null
sudo ln -sf /etc/nginx/sites-available/moyu.conf /etc/nginx/sites-enabled/moyu.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo chmod o+rx "$HOME"
sudo nginx -t
sudo systemctl reload nginx
echo "Nginx 已更新"
