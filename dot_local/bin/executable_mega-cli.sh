#!/bin/bash

# ==========================================
# 共用函数
# ==========================================
header() {
    clear
    echo "=========================================="
    echo "            MEGAcmd 跨平台管理器            "
    echo "=========================================="
}

pause() {
    echo "------------------------------"
    read -rp "按回车键返回主菜单..."
}

is_quit() {
    [[ -z "$1" || "$1" == [Qq] ]]
}

# 检查 MEGAcmd 是否安装
if ! command -v mega-login >/dev/null 2>&1; then
    echo "错误：找不到 MEGAcmd。"
    echo "请先安装 MEGAcmd 后再执行本程序。"
    exit 1
fi
# ==========================================
# 主程序逻辑
# ==========================================
while true; do
header

whoami_out="$(mega-whoami 2>/dev/null)"
if [ -n "$whoami_out" ]; then
    printf " %s\n" "$whoami_out"
else
    echo "未登录"
fi
    echo "=========================================="
    echo " 1. 登录账号"
    echo " 2. 查看云端文件"
    echo " 3. 查看同步任务"
    echo " 4. 开启同步任务"
    echo " 5. 断开同步任务"
    echo " 6. 退出程序"
    echo "=========================================="
    read -rp "请输入选项数字(1-6): " choice

    case $choice in
    
        1)
            echo ""
            echo "--- 登录 MEGA 账号 ---"
            read -rp "请输入 Email 邮箱: " email
            read -s -rp "请输入密码 (输入时屏幕不显示): " password
            echo ""
            echo "正在登录中，请稍候..."
            mega-login "$email" "$password"
            pause
            ;;
        2)
            echo ""
            echo "--- MEGA 云端根目录文件列表 ---"
            mega-ls /
            pause
            ;;
        3)
            echo "--- 已有同步 ---"
            mega-sync
            pause
            ;;
        4)
            echo "--- 已有同步 ---"
            mega-sync
            echo "--- 建立实时同步 (输入 q 返回主菜单) ---"
            read -rp "请输入本地文件夹路径 (例如 ~/Documents): " local_path
            # 检查是否输入了 q
            if is_quit "$local_path"; then
                continue
            fi
            
            echo "--- 云端目录 ---"
            mega-ls /
            
            read -rp "请输入云端文件夹路径 (例如 /Backup): " remote_path
            # 检查是否输入了 q
            if is_quit "$remote_path"; then
                continue
            fi
            
            local_path="${local_path/#\~/$HOME}"
            
            # 自动创建机制：路径不存在时自动创建
            if ! mkdir -p "$local_path"; then
                echo "错误: 自动创建文件夹失败，请检查权限！"
                continue
            fi
            
            echo "正在建立同步对..."
            mega-sync "$local_path" "$remote_path"
            pause
            ;;
        5)
            echo ""
            echo "--- 当前正在运行的同步任务 ---"
            mega-sync 
            echo "----------------------------------------"
            echo "提示: 输入 q 可取消并返回主菜单"
            read -rp "请输入你想断开的【同步 ID】或【本地路径】: " sync_target
            # 检查是否输入了 q
            if is_quit "$sync_target"; then
                continue
            fi
            
            mega-sync -d "$sync_target"
            pause
            ;;
        6)
            echo "感谢使用，再见！"
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择！"
            ;;
   esac
done
