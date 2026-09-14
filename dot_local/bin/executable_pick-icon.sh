#!/bin/bash
set -euo pipefail

THEME=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")

THEMES=$(find "$HOME/.local/share/icons" "/usr/share/icons" \
    -maxdepth 2 -name index.theme -printf '%h\n' 2>/dev/null \
    | xargs -n1 basename | sort -u)

NEW=$(printf '%s\n' "$THEMES" | fzf --prompt="[当前: $THEME] 选择图标主题: ")
[ -z "$NEW" ] && exit 1
[ "$NEW" = "$THEME" ] && echo "已是当前主题" && exit 0

gsettings set org.gnome.desktop.interface icon-theme "$NEW"
echo "已切换: $THEME -> $NEW"

if [ -d "$HOME/.local/share/icons/$NEW" ]; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/$NEW" || true
fi
