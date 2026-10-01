#!/bin/bash

export PATH="$HOME/.local/bin:$PATH"
TARGET_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null)"
[ -n "$TARGET_DIR" ] && [ "$TARGET_DIR" != "$HOME" ] || TARGET_DIR="$HOME/下载"

if ! command -v anyflip-downloader > /dev/null; then
    echo "未检测到 anyflip-downloader，正在安装..."
    curl -L https://raw.githubusercontent.com/Lofter1/anyflip-downloader/main/scripts/install.sh | /usr/bin/env bash || { echo "安装失败，请检查网络后重试。"; exit 1; }
fi

mkdir -p "$TARGET_DIR"

cd "$TARGET_DIR" || exit

echo "=========================================="
echo "    AnyFlip 下载器"
echo "=========================================="
echo "当前保存路径: $TARGET_DIR"
echo "------------------------------------------"

read -p "请输入 AnyFlip 书籍的完整地址: " url
url="${url//[[:cntrl:]]/}"

if [ -n "$url" ]; then
    echo "正在开始下载任务..."
    if anyflip-downloader -chunksize 10 -retries 5 -threads 5 "$url"; then
        echo "------------------------------------------"
        echo "下载完成！"

        # 发送系统通知
        notify-send "AnyFlip 下载器" "书籍已成功保存至下载文件夹" --icon=folder-open

        # 打开下载文件夹
        xdg-open "$TARGET_DIR" > /dev/null 2>&1
    else
        echo "下载失败，请检查网络或链接后重试。"
        notify-send "AnyFlip 下载器" "下载失败" --icon=error
    fi

else
    echo "错误：未输入 URL，操作已取消。"
    notify-send "AnyFlip 下载器" "错误：未输入有效地址" --icon=error
fi

echo "=========================================="
read -p "按回车键退出..."
