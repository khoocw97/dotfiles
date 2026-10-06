CONFIG := $(HOME)/.config/chezmoi/chezmoi.toml
# 与 .chezmoi.toml.tmpl 的 sourceDir 保持一致
SOURCE := $(HOME)/Project/dotfiles
REPO   := https://github.com/khoocw97/dotfiles.git
THEMES := gruvbox-dark gruvbox-light tokyonight

.PHONY: help install reset fix-audio-msi $(THEMES)

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

reset: tokyonight ## 重置到默认主题（= make tokyonight）

fix-audio-msi: ## 安装音频修复 service 并启用 (MSI)
	@install -D -m 644 "$(SOURCE)/dot_config/systemd/user/msige602pl-fix-audio.service" "$(HOME)/.config/systemd/user/msige602pl-fix-audio.service"
	@systemctl --user daemon-reload
	@systemctl --user enable --now msige602pl-fix-audio.service
	@echo Done

define apply-theme
	@test "$$(grep -c '^theme = ' $(CONFIG) 2>/dev/null)" = 1 || \
		{ echo "$(CONFIG) 主题行异常，先跑 make install"; exit 1; }
	@sed -i 's/^theme = .*/theme = "$(1)"/' $(CONFIG)
	@chezmoi apply
	@busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
	@niri msg action load-config-file >/dev/null 2>&1 || true
	@umbriel msg config-reload >/dev/null 2>&1 || true
	@noctalia msg config-reload >/dev/null 2>&1 || true
	@bat cache --build >/dev/null 2>&1 || true
	@echo Done
endef

$(THEMES):
	$(call apply-theme,$@)
