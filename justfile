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

# reset to tokyonight
[group('command')]
reset: (_apply-theme "tokyonight")

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
    @bat cache --build >/dev/null 2>&1 || true
    @echo Done
