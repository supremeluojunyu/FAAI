#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRP_DIR="${FRP_DIR:-$HOME/frp_0.52.3_linux_amd64}"
FRPC_TOML="${FRPC_TOML:-$FRP_DIR/frpc.toml}"

echo "==> 应用 Nginx（含 127.0.0.1:9080 Proxy Protocol）"
bash "$ROOT_DIR/scripts/apply-nginx-config.sh"

if [[ ! -f "$FRPC_TOML" ]]; then
  echo "未找到 $FRPC_TOML，请从 deploy/frp/frpc.toml.example 复制并填写 token 后重试"
  exit 1
fi

if ! grep -q 'localPort = 9080' "$FRPC_TOML" || ! grep -q 'proxyProtocolVersion' "$FRPC_TOML"; then
  echo "警告: $FRPC_TOML 需 localPort=9080 且 transport.proxyProtocolVersion=v2"
  echo "参见 deploy/frp/README.md"
fi

echo "==> 重启 frpc"
sudo systemctl restart frpc
sleep 1
systemctl is-active frpc

echo "==> 重建并重启后端"
(cd "$ROOT_DIR/backend" && npm run build)
sudo systemctl restart moyu-backend

echo "完成。请从公网访问一次后检查管理端「用户日志」IP 列。"
