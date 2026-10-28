CONFIG := $(HOME)/.config/chezmoi/chezmoi.toml
# 与 .chezmoi.toml.tmpl 的 sourceDir 保持一致
SOURCE := $(HOME)/Project/dotfiles
REPO   := https://github.com/khoocw97/dotfiles.git
THEMES := gruvbox-dark gruvbox-light tokyonight
# 无映射则保持当前壁纸
WALLS_tokyonight    := $(HOME)/Pictures/Wallpapers/wallpaper-96yottea.jpg
WALLS_gruvbox-light := $(HOME)/Pictures/Wallpapers/The_Backwater.jxl
WALLS_gruvbox-dark  := $(HOME)/Pictures/Wallpapers/gruvbox_image46.png

.PHONY: help install reset msi firefox $(THEMES)

help:
	@echo ""
	@echo "Run make install for first-time setup (prompts for theme)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Themes:"
	@$(foreach t,$(THEMES),printf "\033[36m%-30s\033[0m %s\n" "$(t)" "make $(t)";)

install: ## chezmoi init (clone repo if missing), default tokyonight
	@ [ -d "$(SOURCE)/.git" ] || git clone "$(REPO)" "$(SOURCE)"
	chezmoi -S "$(SOURCE)" apply --init
	@$(MAKE) --no-print-directory firefox

reset: tokyonight ## 重置到默认主题（= make tokyonight）

msi: ## 安装 MSI 服务
	@install -D -m 644 "$(SOURCE)/dot_config/systemd/user/msige602pl-fix-audio.service" "$(HOME)/.config/systemd/user/msige602pl-fix-audio.service"
	@install -D -m 644 "$(SOURCE)/dot_config/systemd/user/obs-studio.service" "$(HOME)/.config/systemd/user/obs-studio.service"
	@install -D -m 644 "$(SOURCE)/dot_config/systemd/user/ferdium.service" "$(HOME)/.config/systemd/user/ferdium.service"
	@systemctl --user daemon-reload
	@systemctl --user enable --now msige602pl-fix-audio.service obs-studio.service ferdium.service
	@echo Done

firefox: ## 安装 firefox - no rounded
	@src="$$HOME/.config/mozilla/firefox/theme"; \
	[ -d "$$src" ] || { echo "主题目录不存在: $$src，跳过"; exit 0; }; \
	found=0; \
	for base in \
		"$$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox" \
		"$$HOME/.config/mozilla/firefox"; do \
		if [ ! -d "$$base" ]; then \
			echo "未检测到: $$base，跳过"; \
			continue; \
		fi; \
		hit=0; \
		for profile in "$$base"/*.default-release; do \
			[ -d "$$profile" ] || continue; \
			hit=1; found=1; \
			cp -a "$$src"/. "$$profile"/; \
			echo "Firefox theme: $$src -> $$profile"; \
		done; \
		[ "$$hit" = 1 ] || echo "$$base 下无 *.default-release，跳过"; \
	done; \
	[ "$$found" = 1 ] || echo "flatpak/原生 均无可用 profile，跳过"

define apply-theme
	@test "$$(grep -c '^theme = ' $(CONFIG) 2>/dev/null)" = 1 || \
		{ echo "$(CONFIG) 主题行异常，先跑 make install"; exit 1; }
	@sed -i 's/^theme = .*/theme = "$(1)"/' $(CONFIG)
	@chezmoi apply
	@busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
	@niri msg action load-config-file >/dev/null 2>&1 || true
	@umbriel msg config-reload >/dev/null 2>&1 || true
	@noctalia msg config-reload >/dev/null 2>&1 || true
	@[ -z "$(WALLS_$(1))" ] || noctalia msg wallpaper-set "$(WALLS_$(1))" >/dev/null 2>&1 || true
	@bat cache --build >/dev/null 2>&1 || true
	@echo Done
endef

$(THEMES):
	$(call apply-theme,$@)
