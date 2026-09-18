CONFIG := $(HOME)/.config/chezmoi/chezmoi.toml

.PHONY: install gruvbox-dark tokyonight

install:
	chezmoi apply --init

# 切换主题
gruvbox-dark tokyonight: %:
	@test "$$(grep -c '^theme = ' $(CONFIG) 2>/dev/null)" = 1 || \
		{ echo "$(CONFIG) 主题行异常，先跑 make install"; exit 1; }
	@sed -i 's/^theme = .*/theme = "$@"/' $(CONFIG)
	chezmoi apply
	-busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1
