# AGENTS.md — dotfiles 主题系统约定

所有主题工作必须遵循本文件。违反任一条即为错误。

## 1. 唯一开关

- 变量 `theme`，合法值只有三个：`tokyonight`（默认）、`gruvbox-dark`、`gruvbox-light`。
- 存放：`~/.config/chezmoi/chezmoi.toml` 的 `[data] theme`；默认值在 `.chezmoi.toml.tmpl`。
- 切换：`just <theme>`（如 `just gruvbox-dark`），初装 `just install`，重置 `just reset`（= `just tokyonight`）。临时的单次覆盖用
  `chezmoi <cmd> --override-data '{"theme":"gruvbox-dark"}'`（不持久化）。
- 模板里读变量必须用安全写法 `{{ get . "theme" | default "tokyonight" }}`，
  直接 `{{ .theme }}` 会因 `missingkey=error` 炸掉。

## 2. 铁律：主题名处处一致

主题值必须同时等于以下各者，加新主题只加名字、不改逻辑：

- `.chezmoitemplates/kitty/<value>.conf`
- `starship.toml` 的 `[palettes.<value>]`
- fcitx5 主题目录 `themes/<value>/`
- yazi flavor 目录 `flavors/<value>.yazi/`
- `.chezmoitemplates/niri/<value>.kdl`（经 `colour.kdl` 分发）
- noctalia palette 文件 `palettes/<value>.json`（v2 格式：顶层 `version: 2`，键用 role 名；经 `custom_palette` 选中；主题名含 `light` 自动走浅色 mode）
- bat 主题文件 `themes/<value>.tmTheme`（内置 `name` 必须等于主题值，`config` 里 `--theme={{ .theme }}`）
- `.chezmoitemplates/fuzzel/<value>.ini`（经 `fuzzel.ini` 分发，只含 `[colors]`，`border` 跟 niri focus-ring；
  `font`/`[border]` 与主题无关放主文件：字体同 kitty，`width=5`/`radius=0` 对齐 umbriel）
- `.chezmoitemplates/kde/<value>.colors`（经 `private_kdeglobals` 分发到 `~/.config/kdeglobals`，
  同时各自安装为 `~/.local/share/color-schemes/<value>.colors`）

打错主题名必须大声报错，禁止静默回落到默认分支。

## 3. 各软件接线方式

| 软件 | 机制 | 模板行数 |
|---|---|---|
| kitty | `includeTemplate (printf "kitty/%s.conf" ...)` 动态分发 | 1 行 |
| starship | 原生 `[palettes.*]`，只模板化 `palette =` | 1 行 |
| fcitx5 | 整目录双份（flat 无 SVG），`classicui.conf` 里 `Theme={{ .theme }}` | 1 行 |
| yazi | flavor 双份，`theme.toml` 里 `dark/light = "{{ .theme }}"` | 2 行 |
| niri | `colour.kdl` 分发 `.chezmoitemplates/niri/<value>.kdl`（单 `layout` 块，中性值各片段自带） | 1 行 |
| bat | 自带主题双份 `themes/<value>.tmTheme` + `config` 里 `--theme=` 一行；增量主题后必跑 `bat cache --build`（已进 justfile） | 1 行 |
| fuzzel | `fuzzel.ini` 分发 `.chezmoitemplates/fuzzel/<value>.ini`（只含 `[colors]`，RGBA 无 `#` 小写，`border` 跟 niri focus-ring；主文件另带 `font` + `[border]`，字体同 kitty，`width=5`/`radius=0`） | 1+2 行 |
| zed | `settings.json` 里 `theme` 一行：tokyonight 用已装扩展主题 `Tokyo Night`，gruvbox-dark 用内置 `Gruvbox Dark Hard`，gruvbox-light 用内置 `Gruvbox Light`（不是 `Gruvbox Light Hard`）；`settings.json` 其余内容原样保留，插件在 Zed 数据目录不受 chezmoi 管理 | 1 行 |
| kde | `private_kdeglobals` 分发 `.chezmoitemplates/kde/<value>.colors`（完整 KDE 色彩方案，含 `[General]`）；`[Colors:Header][Inactive]` 与 `[Colors:Header]` 全等、`[WM]` inactive 与 active 全等、`ColorEffects:Inactive` 关闭，避免焦点切换变色；同一份另装到 `~/.local/share/color-schemes/<value>.colors` | 1+3 行 |
| noctalia | 自带 palette 双份 `palettes/<value>.json`（v2 格式：顶层 `version: 2`，键用 role 名，只写 `dark`，`light` 缺省回落 dark），`setting.toml` 里 `source = "custom"` + `custom_palette = "{{ .theme }}"` + `mode = "{{ if contains "light" (get . "theme") }}light{{ else }}dark{{ end }}"`（名字含 `light` 才认浅色，`shell_mode = "follow"` 跟随；**别写死 `mode = "dark"`**：palette 的 `dark`/`light` 是两套独立派生公式，浅色色值塞进 dark 分支会被夹成深色）；`[shell]` 固定 `app_icon_color = "on_surface_variant"`（角色名引用，自动跟主题，静态行不算模板），v5.5 起着色开关是各组件自己的 `colorize_icons = true`（audio/dock/notification/launcher/window_switcher/taskbar/workspaces/tray/active_window/widget），另有 `polkit_colorize_icons` / `screen_time_colorize_icons`，旧 `app_icon_colorize` 已移除；`builtin_ids` 只留 gtk3/gtk4/qt 给 GTK/Qt 用，`community_ids` 保持空；KDE 色彩方案不交给 noctalia 的 kcolorscheme，走上面的 kde 分发；kitty/niri/yazi/fcitx5/starship 一律不管（noctalia 再生成它们的文件就是打架） | 2 行 |

原则：软件原生支持多主题用原生的（starship palettes）；没有才用 chezmoi 分发。
fcitx5 主题禁止 SVG/透明色（出过生产事故：`fill-opacity < 1` 导致整框发虚），纯色优先。
`just <theme>` 落盘后顺手热加载：fcitx5 走 `busctl … ReloadAddonConfig`、
niri 走 `niri msg action load-config-file`、umbriel 走 `umbriel msg config-reload`、
noctalia 走 `noctalia msg config-reload`；
四行一律 `@… || true`，没装对应软件/没跑 compositor 的机器静默跳过。

## 4. 色板（唯一真源，改色先改这里再同步各文件）

tokyonight：surface `#212736` / fg `#e3e5e5` / blue `#769ff0` / panel `#394260` /
time_bg `#1d2230` / os_bg `#a3aed2` / os_fg `#090c0c` /
red `#f7768e` / green `#9ece6a` / yellow `#e0af68` / purple `#bb9af7` /
cyan `#7dcfff` / orange `#ff9e64` / grey `#545c7e`

gruvbox-dark（gruvbox-material, dark + background=hard + foreground=material）：
surface `#282828` / fg `#ddc7a1` / blue `#7daea3` / panel `#32302f` / bg3 `#3c3836` /
time_bg `#141617` / os_bg `#d8a657` / os_fg `#1d2021` /
red `#ea6962` / orange `#e78a4e` / yellow `#d8a657` / green `#a9b665` /
aqua `#89b482` / purple `#d3869b` / grey `#928374`

gruvbox-light（gruvbox-material, light + background=hard + foreground=material）：
surface `#f5edca` / fg `#4f3829` / blue `#45707a` / panel `#f3eac7` / bg3 `#f2e5bc` /
time_bg `#f3eac7` / os_bg `#654735` / os_fg `#f9f5d7` /
red `#c14a4a` / orange `#c35e0a` / yellow `#b47109` / green `#6c782e` /
aqua `#4c7a5d` / purple `#945e80` / grey `#928374`
（kitty `background` 三主题用 `#1a1b26` / `#1d2021` / light-medium bg0 `#fbf1c7`，noctalia `surface`（顶栏）跟 kitty `background` 走、不跟上面 surface；umbriel `unfocused` 双 gruvbox 用透明（`#1d202100` / `#f9f5d700`）；
os_bg 不用 yellow：`#b47109` 配深/浅字分别是 2.75/3.59，均 < 4.5，改用 fg0 `#654735` 配 `#f9f5d7` 得 7.61；
noctalia `primary` 同理用 blue `#45707a` 配 `#f9f5d7` 得 4.95，`secondary` 用 aqua 4.49 / `error` 用 red 4.39 系上游浅色极限，已注明）
KDE：`bg_view` 跟 kitty `background`，`bg_window` 跟 surface，`bg_header` 跟 time_bg，`bg_button` 跟 bg3（tokyonight 用 panel），selection 用 accent 配 os_fg；两个 gruvbox 的 inactive header/WM 必须与 active 全等。

## 5. 机器分流

`.chezmoiignore` 按 `XDG_CURRENT_DESKTOP`（=`env "XDG_CURRENT_DESKTOP"|lower`）ignore 整目录：
含 `niri` 只留 niri，含 `umbriel` 只留 umbriel。source 根的非管理文件
（README.md、AGENTS.md 等）必须同步加进 `.chezmoiignore`，
否则会被当成 `~/` 目标文件。

## 6. 验证铁律

- 改模板必跑全主题 `chezmoi cat` 渲染 + TOML/语法校验；starship 改完必跑
  `STARSHIP_CONFIG=<render> starship prompt` 真加载。
- 纯重构（拆文件、改名）必须重构前后渲染 `diff` 为空（注释行改写除外）。
- 对比度：彩底上的字至少 4.5:1，算完再提交（`python3` 现算）。
- 跑完 `just <theme>` 切回来，保持工作区停在改动前的主题。

## 7. 输入法开关

`just fcitx5` / `just ibus` 只写环境变量，别的一概不做（自启仍在 niri/umbriel 的 autostart 里）。

- `~/.config/environment.d/im.conf`：`QT_IM_MODULES=wayland;<mod>`、`QT_IM_MODULE`、
  `XMODIFIERS=@im=<mod>`、`SDL_IM_MODULE`。
- **不设 `GTK_IM_MODULE`**：Wayland 下设了坏。Xwayland 的 GTK 靠
  `~/.config/gtk-3.0/settings.ini` 的 `gtk-im-module=<mod>`。
- flatpak 读不到 settings.ini，用 `flatpak override --user --env=GTK_IM_MODULE=… --env=QT_IM_MODULE=…` 全局覆盖。
- 环境变量要重新登录才生效。

## 8. just 与 make 同步

`Makefile` 是 `justfile` 的手工重写版（不调用 just：Ubuntu 24.04 的 just 1.21
没有 `[group]`，Debian bookworm 源里干脆没有 just，这些机器只能走 `make`）。

- 改 `justfile` 的任何 recipe，必须在同一次改动里同步进 `Makefile`；两边目标名、
  行为、文案保持一致（`apply-theme`/`write-im` 对应 `_apply-theme`/`_write-im`）。
- `make` 默认 `help` 列目标；`just` 继续用 `[group(...)]` 分组，两边互不影响。
- 两文件都在 `.chezmoiignore` 里，不会被当 `~/` 目标文件分发。
