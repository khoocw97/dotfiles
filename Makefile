CONFIG := $(HOME)/.config/chezmoi/chezmoi.toml
THEMES := gruvbox-dark tokyonight

.PHONY: help install $(THEMES)

help:
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "切换对应主题:"
	@$(foreach t,$(THEMES),printf "\033[36m%-30s\033[0m %s\n" "$(t)" "make $(t)";)

install: ## 安装dotfiles, 默认tokyonight或make install "theme"
	chezmoi apply --init

define apply-theme
	@test "$$(grep -c '^theme = ' $(CONFIG) 2>/dev/null)" = 1 || \
		{ echo "$(CONFIG) 主题行异常，先跑 make install"; exit 1; }
	@sed -i 's/^theme = .*/theme = "$(1)"/' $(CONFIG)
	@chezmoi apply
	-@busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
	-@niri msg action load-config-file >/dev/null 2>&1 || true
	-@umbriel msg config-reload >/dev/null 2>&1 || true
	-@noctalia msg config-reload >/dev/null 2>&1 || true
	@echo Done
endef

$(THEMES):
	$(call apply-theme,$@)
