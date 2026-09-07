#!/bin/bash
set -e
TARGET_DIR="/etc/ly"
TARGET_FILE="$TARGET_DIR/config.ini"
SOURCE_FILE="$CHEZMOI_SOURCE_DIR/private_dot_config/ly/config.ini"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ 错误: 找不到 $SOURCE_FILE"
    exit 1
fi

sudo mkdir -p "$TARGET_DIR"
sudo cp "$SOURCE_FILE" "$TARGET_FILE"
sudo chown root:root "$TARGET_FILE"
sudo chmod 644 "$TARGET_FILE"
echo "✅ /etc/ly/config.ini 已成功部署"
