# dotfiles runner (mirrors Makefile). Usage: `just --list`

CONFIG := env_var('HOME') + '/.config/chezmoi/chezmoi.toml'
# 与 .chezmoi.toml.tmpl 的 sourceDir 保持一致
SOURCE := env_var('HOME') + '/Project/dotfiles'
REPO := 'https://github.com/khoocw97/dotfiles.git'

[private]
default:
    @just --list

# chezmoi init (clone repo if missing), default tokyonight
[group('command')]
install:
    @[ -d "{{SOURCE}}/.git" ] || git clone "{{REPO}}" "{{SOURCE}}"
    @chezmoi -S "{{SOURCE}}" apply --init
    @just firefox

# reset to tokyonight
[group('command')]
reset: (_apply-theme "tokyonight")

# install audio-fix service and enable it (MSI)
[group('command')]
fix-audio-msi:
    @install -D -m 644 "{{SOURCE}}/dot_config/systemd/user/msige602pl-fix-audio.service" "$HOME/.config/systemd/user/msige602pl-fix-audio.service"
    @systemctl --user daemon-reload
    @systemctl --user enable --now msige602pl-fix-audio.service
    @echo Done

# install firefox - no rounded
[group('command')]
firefox:
    #!/usr/bin/env bash
    src="$HOME/.config/mozilla/firefox/theme"
    [ -d "$src" ] || { echo "主题目录不存在: $src，跳过"; exit 0; }
    found=0
    for base in \
        "$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox" \
        "$HOME/.config/mozilla/firefox"; do
        if [ ! -d "$base" ]; then
            echo "未检测到: $base，跳过"
            continue
        fi
        hit=0
        for profile in "$base"/*.default-release; do
            [ -d "$profile" ] || continue
            hit=1; found=1
            cp -a "$src"/. "$profile"/
            echo "Firefox theme: $src -> $profile"
        done
        [ "$hit" = 1 ] || echo "$base 下无 *.default-release，跳过"
    done
    [ "$found" = 1 ] || echo "flatpak/原生 均无可用 profile，跳过"

# install obs autostart service and enable it (MSI)
[group('command')]
obs:
    @install -D -m 644 "{{SOURCE}}/dot_config/systemd/user/obs-studio.service" "$HOME/.config/systemd/user/obs-studio.service"
    @systemctl --user daemon-reload
    @systemctl --user enable --now obs-studio.service
    @echo Done

[group('theme')]
gruvbox-dark: (_apply-theme "gruvbox-dark")

[group('theme')]
gruvbox-light: (_apply-theme "gruvbox-light")

[group('theme')]
tokyonight: (_apply-theme "tokyonight")

_apply-theme theme:
    @test "$(grep -c '^theme = ' {{CONFIG}} 2>/dev/null)" = 1 || { echo "{{CONFIG}} 主题行异常，先跑 just install"; exit 1; }
    @sed -i 's/^theme = .*/theme = "{{theme}}"/' {{CONFIG}}
    @chezmoi apply
    @busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
    @niri msg action load-config-file >/dev/null 2>&1 || true
    @umbriel msg config-reload >/dev/null 2>&1 || true
    @noctalia msg config-reload >/dev/null 2>&1 || true
    @# 无映射则保持当前壁纸
    @case "{{theme}}" in \
        tokyonight) wp="$HOME/Pictures/Wallpapers/wallpaper-96yottea.jpg" ;; \
        gruvbox-light) wp="$HOME/Pictures/Wallpapers/The_Backwater.jxl" ;; \
        gruvbox-dark) wp="$HOME/Pictures/Wallpapers/gruvbox_image46.png" ;; \
        *) wp="" ;; \
    esac; \
    [ -z "$wp" ] || noctalia msg wallpaper-set "$wp" >/dev/null 2>&1 || true
    @bat cache --build >/dev/null 2>&1 || true
    @echo Done
