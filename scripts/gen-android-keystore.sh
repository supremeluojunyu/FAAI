#!/usr/bin/env bash
# 生成 Android 正式签名密钥（仅需执行一次，务必备份 jks 与密码）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/mobile-app/android"
APP_DIR="$ANDROID_DIR/app"
KEYSTORE="$APP_DIR/moyu-release.jks"
ENV_FILE="$ROOT/config/android-signing.env"
KEY_PROPS="$ANDROID_DIR/key.properties"

if [[ -f "$KEYSTORE" ]]; then
  echo "已存在: $KEYSTORE（跳过生成，避免覆盖导致无法覆盖安装旧版）"
  exit 0
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "需要 keytool，请安装: sudo apt-get install -y openjdk-17-jre-headless"
  exit 1
fi

STORE_PASS="$(openssl rand -base64 24 | tr -d '/+=' | head -c 20)"
KEY_PASS="$STORE_PASS"
KEY_ALIAS="moyu"

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$STORE_PASS" -keypass "$KEY_PASS" \
  -dname "CN=Moyu App, OU=Mobile, O=Moyu, L=Shanghai, ST=Shanghai, C=CN"

mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" <<EOF
KEYSTORE_PASSWORD=$STORE_PASS
KEY_PASSWORD=$KEY_PASS
KEY_ALIAS=$KEY_ALIAS
EOF
chmod 600 "$ENV_FILE"

cat > "$KEY_PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$KEY_ALIAS
storeFile=moyu-release.jks
EOF
chmod 600 "$KEY_PROPS"

B64_FILE="$ROOT/config/android-keystore.b64"
base64 -w0 "$KEYSTORE" > "$B64_FILE"
chmod 600 "$B64_FILE"

echo ""
echo "=== 已生成正式签名 ==="
echo "密钥库: $KEYSTORE"
echo "配置:   $ENV_FILE"
echo "Base64: $B64_FILE  （用于 GitHub Secret ANDROID_KEYSTORE_BASE64）"
echo ""
echo "请到 GitHub 仓库 Settings → Secrets → Actions 添加："
echo "  ANDROID_KEYSTORE_BASE64  = 文件 $B64_FILE 的全部内容"
echo "  ANDROID_KEYSTORE_PASSWORD = （见 $ENV_FILE 的 KEYSTORE_PASSWORD）"
echo "  ANDROID_KEY_PASSWORD        = 同上 KEY_PASSWORD"
echo "  ANDROID_KEY_ALIAS           = moyu"
echo ""
echo "添加后重新打标签发布（如 v0.0.7），此后各版本可覆盖安装。"

bash "$ROOT/scripts/backup-android-keystore.sh"
