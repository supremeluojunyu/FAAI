#!/usr/bin/env bash
# 生产环境完整部署：磁盘扩展 + 系统服务 + Nginx 80 端口
# 用法: bash scripts/vm-prod-complete.sh [VM_IP]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_IP="${1:-$(hostname -I | awk '{print $1}')}"
DB_USER="${DB_USER:-moyu}"
DB_PASS="${DB_PASS:-password}"
DB_NAME="${DB_NAME:-mouldb}"
export PATH="$HOME/.local/bin:$HOME/flutter/bin:$PATH"

log() { echo "[$(date +%H:%M:%S)] $*"; }

ensure_sudo() {
  if sudo -n true 2>/dev/null; then
    log "sudo 免密已生效"
    return
  fi
  log "安装 golden 免密 sudo 配置..."
  sudo cp "$ROOT_DIR/deploy/sudoers/golden-nopasswd" /etc/sudoers.d/golden-nopasswd
  sudo chmod 440 /etc/sudoers.d/golden-nopasswd
  sudo visudo -c
  if ! sudo -n true 2>/dev/null; then
    echo "错误: sudo 免密未生效。请在终端执行:"
    echo "  sudo cp $ROOT_DIR/deploy/sudoers/golden-nopasswd /etc/sudoers.d/"
    echo "  sudo chmod 440 /etc/sudoers.d/golden-nopasswd"
    echo "  sudo visudo -c"
    exit 1
  fi
}

stop_userspace() {
  log "停止用户空间临时服务..."
  export LD_LIBRARY_PATH="$HOME/.local/pgroot/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
  if [ -x "$HOME/.local/pgroot/usr/lib/postgresql/16/bin/pg_ctl" ] && [ -d "$HOME/.local/pgdata" ]; then
    "$HOME/.local/pgroot/usr/lib/postgresql/16/bin/pg_ctl" -D "$HOME/.local/pgdata" stop -m fast 2>/dev/null || true
  fi
  pkill -f "node ${ROOT_DIR}/backend/dist/server.js" 2>/dev/null || true
  pkill -f "node ${ROOT_DIR}/scripts/gateway.mjs" 2>/dev/null || true
  pkill -f "vite --host 0.0.0.0 --port 5173" 2>/dev/null || true
  pkill -f "http.server 8091 --directory ${ROOT_DIR}/mobile-app/build/web" 2>/dev/null || true
  sleep 2
}

extend_disk() {
  lv_size=$(lsblk -b -dn -o SIZE /dev/mapper/ubuntu--vg-ubuntu--lv 2>/dev/null || echo 0)
  avail=$(lsblk -b -dn -o SIZE /dev/sda3 2>/dev/null || echo 0)
  if [ "$avail" -gt 0 ] && [ "$((avail - lv_size))" -gt 5368709120 ]; then
    log "扩展 LVM 磁盘 (59G -> ~118G)..."
    sudo pvresize /dev/sda3
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu-lv
    df -h /
  else
    log "磁盘无需扩展: $(df -h / | tail -1)"
  fi
}

install_system() {
  log "安装系统依赖..."
  sudo apt-get update -y
  sudo apt-get install -y postgresql postgresql-contrib redis-server nginx ufw python3 ripgrep
  sudo systemctl enable --now postgresql redis-server
}

setup_database() {
  log "初始化 PostgreSQL 数据库..."
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';"
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER \"${DB_USER}\";"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO \"${DB_USER}\";" >/dev/null
}

build_apps() {
  log "构建应用..."
  sed -i "s#^DATABASE_URL=.*#DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}#g" "$ROOT_DIR/backend/.env"
  cd "$ROOT_DIR/backend"
  npm install --silent
  npx prisma db push --accept-data-loss
  npm run build

  cd "$ROOT_DIR/admin-web"
  npm install --silent
  npm run build

  cd "$ROOT_DIR/mobile-app"
  export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
  export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
  flutter pub get
  flutter build web
}

write_config() {
  log "同步 FRP 公网配置..."
  node "$ROOT_DIR/scripts/sync-public-config.mjs"
}

setup_nginx() {
  log "配置 Nginx..."
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
  sudo systemctl enable --now nginx
  sudo systemctl restart nginx
}

setup_systemd() {
  log "注册 systemd 服务..."
  NODE_BIN="$(command -v node)"
  NPM_BIN="$(command -v npm)"

  sudo tee /etc/systemd/system/moyu-backend.service >/dev/null <<EOF
[Unit]
Description=Moyu Backend Service
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=${ROOT_DIR}/backend
Environment=NODE_ENV=production
Environment=PATH=${HOME}/.local/bin:${HOME}/flutter/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=${NODE_BIN} ${ROOT_DIR}/backend/dist/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/moyu-admin.service >/dev/null <<EOF
[Unit]
Description=Moyu Admin Web (static build)
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=${USER}
WorkingDirectory=${ROOT_DIR}/admin-web
Environment=PATH=${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=${NPM_BIN} run build

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

  sudo systemctl daemon-reload
  sudo systemctl enable --now moyu-backend moyu-admin moyu-mobile-web
  sudo systemctl restart moyu-backend moyu-admin moyu-mobile-web
}

setup_firewall() {
  log "配置防火墙..."
  sudo ufw allow 22/tcp >/dev/null 2>&1 || true
  sudo ufw allow 80/tcp >/dev/null 2>&1 || true
  sudo ufw allow 443/tcp >/dev/null 2>&1 || true
  sudo ufw --force enable >/dev/null 2>&1 || true
}

setup_logrotate() {
  if [ -f "$ROOT_DIR/deploy/logrotate/moyu-services" ]; then
    log "配置日志轮转..."
    sudo cp "$ROOT_DIR/deploy/logrotate/moyu-services" /etc/logrotate.d/moyu-services 2>/dev/null || true
  fi
}

health_check() {
  log "健康检查..."
  sleep 4
  curl -sf "http://${VM_IP}/" >/dev/null
  curl -sf "http://${VM_IP}/app-config.json" >/dev/null
  curl -sf "http://${VM_IP}/api/v1/models" >/dev/null
  curl -sf "http://${VM_IP}/admin/" >/dev/null || true
}

echo "========================================"
echo " 模宇宙生产环境完整部署  IP=${VM_IP}"
echo "========================================"

ensure_sudo
stop_userspace
extend_disk
install_system
setup_database
build_apps
write_config
setup_nginx
setup_systemd
setup_firewall
setup_logrotate
health_check

echo ""
echo "========================================"
echo " 全部配置完成！"
echo " 网关:   http://${VM_IP}/"
echo " 配置:   http://${VM_IP}/app-config.json"
echo " API:    http://${VM_IP}/api/v1/models"
echo " 管理端: http://${VM_IP}/admin/"
echo " 移动端: http://${VM_IP}/mobile/"
echo " 磁盘:   $(df -h / | tail -1 | awk '{print $2" 总量, "$3" 已用, "$4" 可用"}')"
echo ""
echo " 服务状态:"
sudo systemctl is-active postgresql redis-server nginx moyu-backend moyu-admin moyu-mobile-web
echo "========================================"
