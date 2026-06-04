#!/usr/bin/env bash
# 自动备份 Android 正式签名（密钥库 + 密码配置），保留最近 30 份
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/mobile-app/android/app/moyu-release.jks"
ENV_FILE="$ROOT/config/android-signing.env"
KEY_PROPS="$ROOT/mobile-app/android/key.properties"
BACKUP_ROOT="${MOYU_KEYSTORE_BACKUP_DIR:-$HOME/FAAI-backups/android-signing}"
KEEP="${MOYU_KEYSTORE_BACKUP_KEEP:-30}"

if [[ ! -f "$KEYSTORE" ]]; then
  echo "跳过备份：未找到 $KEYSTORE（可先运行 scripts/gen-android-keystore.sh）"
  exit 0
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
DEST="$BACKUP_ROOT/$STAMP"
mkdir -p "$DEST"
chmod 700 "$BACKUP_ROOT" "$DEST"

cp -a "$KEYSTORE" "$DEST/moyu-release.jks"
[[ -f "$ENV_FILE" ]] && cp -a "$ENV_FILE" "$DEST/android-signing.env"
[[ -f "$KEY_PROPS" ]] && cp -a "$KEY_PROPS" "$DEST/key.properties"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a
  {
    echo "backup_at=$(date -Iseconds)"
    echo "key_alias=${KEY_ALIAS:-moyu}"
    echo "note=请妥善保管此目录，丢失将无法覆盖安装同包名应用"
  } > "$DEST/README.txt"
fi

base64 -w0 "$KEYSTORE" > "$DEST/moyu-release.b64" 2>/dev/null || base64 "$KEYSTORE" > "$DEST/moyu-release.b64"

ls -1dt "$BACKUP_ROOT"/*/ 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -rf

echo "已备份到: $DEST"
