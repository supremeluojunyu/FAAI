#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

VM_IP="${1:-$(hostname -I | awk '{print $1}')}"
DB_USER="${DB_USER:-user}"
DB_PASS="${DB_PASS:-password}"
DB_NAME="${DB_NAME:-mouldb}"

echo "[1/12] 准备数据库..."
sudo systemctl restart postgresql redis-server
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | rg -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | rg -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

echo "[2/12] 写入 backend/.env..."
if [ ! -f "$ROOT_DIR/backend/.env" ]; then
  cp "$ROOT_DIR/backend/.env.example" "$ROOT_DIR/backend/.env"
fi
sed -i "s#^DATABASE_URL=.*#DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}#g" "$ROOT_DIR/backend/.env"
rg -q "^SMS_PROVIDER=" "$ROOT_DIR/backend/.env" || echo "SMS_PROVIDER=mock" >> "$ROOT_DIR/backend/.env"
rg -q "^SMS_CODE_TTL_SEC=" "$ROOT_DIR/backend/.env" || echo "SMS_CODE_TTL_SEC=300" >> "$ROOT_DIR/backend/.env"
rg -q "^WECHAT_APPSECRET=" "$ROOT_DIR/backend/.env" || echo "WECHAT_APPSECRET=" >> "$ROOT_DIR/backend/.env"

echo "[3/12] 同步数据库并构建后端..."
cd "$ROOT_DIR/backend"
npx prisma db push --accept-data-loss
npm run build

echo "[4/12] 构建管理后台..."
cd "$ROOT_DIR/admin-web"
npm run build

echo "[5/12] 构建 Flutter Web..."
cd "$ROOT_DIR/mobile-app"
flutter pub get
flutter build web

echo "[6/12] 生成 app-config.json..."
cat >"$ROOT_DIR/config-server/public/app-config.json" <<EOF
{
  "apiBaseUrl": "http://${VM_IP}/api/v1",
  "wsUrl": "ws://${VM_IP}/ws",
  "features": {
    "enableAI": true,
    "enablePrintService": true,
    "maxUploadSizeMB": 200,
    "enableCommunity": true
  },
  "version": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "maintenance": false
}
EOF

echo "[7/12] 写入 Nginx 网关配置..."
sudo tee /etc/nginx/sites-available/moyu.conf >/dev/null <<EOF
server {
    listen 80;
    server_name ${VM_IP};

    location = /app-config.json {
        alias ${ROOT_DIR}/config-server/public/app-config.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin "*";
        add_header Cache-Control "max-age=60, must-revalidate";
    }

    location /ws {
        proxy_pass http://127.0.0.1:3000/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /admin/ {
        proxy_pass http://127.0.0.1:5173/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /mobile/ {
        proxy_pass http://127.0.0.1:8091/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }

    location / {
        return 200 "Moyu gateway is running\nTry /api/v1/models, /admin/, /mobile/\n";
        add_header Content-Type text/plain;
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/moyu.conf /etc/nginx/sites-enabled/moyu.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo chmod o+rx "$HOME"
sudo nginx -t
sudo systemctl restart nginx

echo "[8/12] 生成 systemd 服务..."
sudo tee /etc/systemd/system/moyu-backend.service >/dev/null <<EOF
[Unit]
Description=Moyu Backend Service
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=${ROOT_DIR}/backend
Environment=NODE_ENV=production
Environment=NVM_DIR=${HOME}/.nvm
ExecStart=/bin/bash -lc '. "\$NVM_DIR/nvm.sh" && npm run start'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/moyu-admin.service >/dev/null <<EOF
[Unit]
Description=Moyu Admin Web Service
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${ROOT_DIR}/admin-web
Environment=NVM_DIR=${HOME}/.nvm
ExecStart=/bin/bash -lc '. "\$NVM_DIR/nvm.sh" && npm run dev -- --host 0.0.0.0 --port 5173'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/moyu-mobile-web.service >/dev/null <<EOF
[Unit]
Description=Moyu Mobile Flutter Web Preview
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${ROOT_DIR}/mobile-app
ExecStart=/usr/bin/python3 -m http.server 8091 --directory ${ROOT_DIR}/mobile-app/build/web
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[9/12] 启动系统服务..."
sudo systemctl daemon-reload
sudo systemctl enable --now moyu-backend moyu-admin moyu-mobile-web

echo "[10/12] 防火墙规则..."
sudo ufw allow 22/tcp >/dev/null || true
sudo ufw allow 80/tcp >/dev/null || true
sudo ufw allow 443/tcp >/dev/null || true
sudo ufw --force enable >/dev/null || true

echo "[11/12] 健康检查..."
curl -sS "http://${VM_IP}/" >/dev/null
curl -sS "http://${VM_IP}/app-config.json" >/dev/null
curl -sS "http://${VM_IP}/api/v1/models" >/dev/null

echo "[12/12] 完成。"
echo "Gateway: http://${VM_IP}/"
echo "Config:  http://${VM_IP}/app-config.json"
echo "API:     http://${VM_IP}/api/v1/models"
echo "Admin:   http://${VM_IP}/admin/"
echo "Mobile:  http://${VM_IP}/mobile/"
