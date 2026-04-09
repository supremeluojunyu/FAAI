#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/7] 安装系统依赖..."
sudo apt-get update -y
sudo apt-get install -y \
  git curl unzip ca-certificates gnupg lsb-release \
  build-essential nginx postgresql postgresql-contrib redis-server \
  ufw openjdk-21-jdk python3 snapd

echo "[2/7] 安装 Node.js (nvm)..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install --lts >/dev/null
nvm use --lts >/dev/null

echo "[3/7] 安装 Flutter..."
if ! command -v flutter >/dev/null 2>&1; then
  sudo snap install flutter --classic
fi

echo "[4/7] 安装 Android SDK 命令行组件..."
sudo apt-get install -y android-sdk android-sdk-platform-tools android-sdk-build-tools
sudo mkdir -p /usr/lib/android-sdk/cmdline-tools
if [ ! -x /usr/lib/android-sdk/cmdline-tools/latest/bin/sdkmanager ]; then
  TMP_ZIP="/tmp/commandlinetools.zip"
  curl -L "https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip" -o "$TMP_ZIP"
  sudo unzip -q -o "$TMP_ZIP" -d /usr/lib/android-sdk/cmdline-tools
  sudo rm -rf /usr/lib/android-sdk/cmdline-tools/latest
  sudo mv /usr/lib/android-sdk/cmdline-tools/cmdline-tools /usr/lib/android-sdk/cmdline-tools/latest
fi
sudo chown -R "$USER:$USER" /usr/lib/android-sdk

if ! rg -q "ANDROID_HOME=/usr/lib/android-sdk" "$HOME/.bashrc"; then
  cat >>"$HOME/.bashrc" <<'EOF'
export ANDROID_HOME=/usr/lib/android-sdk
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
EOF
fi

export ANDROID_HOME=/usr/lib/android-sdk
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
mkdir -p "$HOME/.android"
touch "$HOME/.android/repositories.cfg"
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null
sdkmanager --sdk_root="$ANDROID_HOME" --install \
  "platform-tools" "platforms;android-36" "build-tools;34.0.0" "build-tools;28.0.3" >/dev/null

echo "[5/7] 启动数据库与缓存服务..."
sudo systemctl enable --now postgresql redis-server

echo "[6/7] 安装项目依赖..."
cd "$ROOT_DIR/backend" && npm install
cd "$ROOT_DIR/admin-web" && npm install
cd "$ROOT_DIR/mobile-app" && flutter pub get

echo "[7/7] 完成。"
echo "请继续执行: bash \"$ROOT_DIR/scripts/oneclick_deploy.sh\""
