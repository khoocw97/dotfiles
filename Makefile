# justfile 的等价实现，供旧机器（just 1.21 / 无 just）使用。
# 不走 just：所有逻辑在这里重写一份，改 justfile 必须同步本文件（AGENTS.md §8）。

SHELL := bash
.DEFAULT_GOAL := help

CONFIG := $(HOME)/.config/chezmoi/chezmoi.toml
# 与 .chezmoi.toml.tmpl 的 sourceDir 保持一致
SOURCE := $(HOME)/Project/dotfiles
REPO   := https://github.com/khoocw97/dotfiles.git

.PHONY: help install reset msi sunshine firefox ibus fcitx5 \
        tokyonight gruvbox-dark gruvbox-light apply-theme write-im

help:
	@echo "make install         chezmoi init (clone repo if missing), default tokyonight"
	@echo "make reset           reset to tokyonight"
	@echo "make tokyonight | gruvbox-dark | gruvbox-light"
	@echo "make msi             install MSI services"
	@echo "make sunshine        sunshine autostart on boot"
	@echo "make firefox         install firefox - no rounded"
	@echo "make fcitx5 | ibus   setup input-method environment variables"

install:
	@[ -d "$(SOURCE)/.git" ] || git clone "$(REPO)" "$(SOURCE)"
	@chezmoi -S "$(SOURCE)" apply --init
	@$(MAKE) --no-print-directory firefox

reset:
	@$(MAKE) --no-print-directory apply-theme THEME=tokyonight

msi:
	@for s in msige602pl-fix-audio obs-studio ferdium sunshine; do \
	    install -D -m 644 "$(SOURCE)/dot_config/systemd/user/$$s.service" "$(HOME)/.config/systemd/user/$$s.service" || exit 1; \
	done
	@systemctl --user daemon-reload
	@systemctl --user enable --now msige602pl-fix-audio.service obs-studio.service ferdium.service sunshine.service
	@echo Done

sunshine:
	@install -D -m 644 "$(SOURCE)/dot_config/systemd/user/sunshine.service" "$(HOME)/.config/systemd/user/sunshine.service"
	@systemctl --user daemon-reload
	@systemctl --user enable --now sunshine.service
	@echo Done

firefox:
	@src="$(HOME)/.config/mozilla/firefox/theme"; \
	[ -d "$$src" ] || { echo "主题目录不存在: $$src，跳过"; exit 0; }; \
	found=0; \
	for base in \
	    "$(HOME)/.var/app/org.mozilla.firefox/config/mozilla/firefox" \
	    "$(HOME)/.config/mozilla/firefox"; do \
	    if [ ! -d "$$base" ]; then \
	        echo "未检测到: $$base，跳过"; \
	        continue; \
	    fi; \
	    hit=0; \
	    for profile in "$$base"/*.default-release; do \
	        [ -d "$$profile" ] || continue; \
	        hit=1; found=1; \
	        cp -a "$$src"/. "$$profile"/ || exit 1; \
	        echo "Firefox theme: $$src -> $$profile"; \
	    done; \
	    [ "$$hit" = 1 ] || echo "$$base 下无 *.default-release，跳过"; \
	done; \
	[ "$$found" = 1 ] || echo "flatpak/原生 均无可用 profile，跳过"

ibus:
	@$(MAKE) --no-print-directory write-im IM=ibus

fcitx5:
	@$(MAKE) --no-print-directory write-im IM=fcitx5

tokyonight:
	@$(MAKE) --no-print-directory apply-theme THEME=tokyonight

gruvbox-dark:
	@$(MAKE) --no-print-directory apply-theme THEME=gruvbox-dark

gruvbox-light:
	@$(MAKE) --no-print-directory apply-theme THEME=gruvbox-light

apply-theme:
	@test "$$(grep -c '^theme = ' $(CONFIG) 2>/dev/null)" = 1 || { echo "$(CONFIG) 主题行异常，先跑 make install"; exit 1; }
	@sed -i 's/^theme = .*/theme = "$(THEME)"/' $(CONFIG)
	@chezmoi apply
	@busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
	@niri msg action load-config-file >/dev/null 2>&1 || true
	@umbriel msg config-reload >/dev/null 2>&1 || true
	@noctalia msg config-reload >/dev/null 2>&1 || true
	@# 无映射则保持当前壁纸
	@case "$(THEME)" in \
	    tokyonight) wp="$(HOME)/Pictures/Wallpapers/wallpaper-96yottea.jpg" ;; \
	    gruvbox-light) wp="$(HOME)/Pictures/Wallpapers/The_Backwater.jxl" ;; \
	    gruvbox-dark) wp="$(HOME)/Pictures/Wallpapers/gruvbox_image46.png" ;; \
	    *) wp="" ;; \
	esac; \
	[ -z "$$wp" ] || noctalia msg wallpaper-set "$$wp" >/dev/null 2>&1 || true
	@bat cache --build >/dev/null 2>&1 || true
	@echo Done

write-im:
	@case "$(IM)" in fcitx5) mod=fcitx; xmod=@im=fcitx ;; ibus) mod=ibus; xmod=@im=ibus ;; \
	    *) echo "未知输入法: $(IM)（只认 fcitx5 / ibus）" >&2; exit 1 ;; esac; \
	mkdir -p ~/.config/environment.d ~/.config/gtk-3.0; \
	printf 'QT_IM_MODULES=wayland;%s\nQT_IM_MODULE=%s\nXMODIFIERS=%s\nSDL_IM_MODULE=%s\n' \
	    "$$mod" "$$mod" "$$xmod" "$$mod" > ~/.config/environment.d/im.conf; \
	gtk=~/.config/gtk-3.0/settings.ini; \
	touch "$$gtk"; \
	if grep -q '^gtk-im-module=' "$$gtk"; then \
	    sed -i "s/^gtk-im-module=.*/gtk-im-module=$$mod/" "$$gtk" || exit 1; \
	elif grep -q '^\[Settings\]' "$$gtk"; then \
	    sed -i "/^\[Settings\]/a gtk-im-module=$$mod" "$$gtk" || exit 1; \
	else \
	    printf '[Settings]\ngtk-im-module=%s\n' "$$mod" >> "$$gtk"; \
	fi; \
	command -v flatpak >/dev/null && flatpak override --user --env=GTK_IM_MODULE="$$mod" --env=QT_IM_MODULE="$$mod" || true; \
	echo "已写 $(IM) 环境变量，重新登录生效"
