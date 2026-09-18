# AGENTS.md — dotfiles 主题系统约定

所有主题工作必须遵循本文件。违反任一条即为错误。

## 1. 唯一开关

- 变量 `theme`，合法值只有两个：`tokyonight`（默认）、`gruvbox-dark`。
- 存放：`~/.config/chezmoi/chezmoi.toml` 的 `[data] theme`；默认值在 `.chezmoi.toml.tmpl`。
- 切换：`make <theme>`（如 `make gruvbox-dark`），初装 `make install`。临时的单次覆盖用
  `chezmoi <cmd> --override-data '{"theme":"gruvbox-dark"}'`（不持久化）。
- 模板里读变量必须用安全写法 `{{ get . "theme" | default "tokyonight" }}`，
  直接 `{{ .theme }}` 会因 `missingkey=error` 炸掉。

## 2. 铁律：五名合一

主题值必须同时等于以下五者，加新主题只加名字、不改逻辑：

- `.chezmoitemplates/kitty/<value>.conf`
- `starship.toml` 的 `[palettes.<value>]`
- fcitx5 主题目录 `themes/<value>/`
- yazi flavor 目录 `flavors/<value>.yazi/`
- `.chezmoitemplates/niri/<value>.kdl`（经 `colour.kdl` 分发）

打错主题名必须大声报错，禁止静默回落到默认分支。

## 3. 各软件接线方式

| 软件 | 机制 | 模板行数 |
|---|---|---|
| kitty | `includeTemplate (printf "kitty/%s.conf" ...)` 动态分发 | 1 行 |
| starship | 原生 `[palettes.*]`，只模板化 `palette =` | 1 行 |
| fcitx5 | 整目录双份（flat 无 SVG），`classicui.conf` 里 `Theme={{ .theme }}` | 1 行 |
| yazi | flavor 双份，`theme.toml` 里 `dark/light = "{{ .theme }}"` | 2 行 |
| niri | `colour.kdl` 分发 `.chezmoitemplates/niri/<value>.kdl`（单 `layout` 块，中性值各片段自带） | 1 行 |
| noctalia | 只留 `builtin_ids = gtk3/gtk4/qt` 给 GTK/Qt 用，`community_ids` 保持空；kitty/niri/yazi/fcitx5/starship 一律不管（noctalia 再生成它们的文件就是打架） | — |

原则：软件原生支持多主题用原生的（starship palettes）；没有才用 chezmoi 分发。
fcitx5 主题禁止 SVG/透明色（出过生产事故：`fill-opacity < 1` 导致整框发虚），纯色优先。

## 4. 色板（唯一真源，改色先改这里再同步各文件）

tokyonight：surface `#212736` / fg `#e3e5e5` / blue `#769ff0` / panel `#394260` /
time_bg `#1d2230` / os_bg `#a3aed2` / os_fg `#090c0c` /
red `#f7768e` / green `#9ece6a` / yellow `#e0af68` / purple `#bb9af7` /
cyan `#7dcfff` / orange `#ff9e64` / grey `#545c7e`

gruvbox-dark（gruvbox-material, dark + background=hard + foreground=material）：
surface `#282828` / fg `#ddc7a1` / blue `#7daea3` / panel `#32302f` /
time_bg `#141617` / os_bg `#d8a657` / os_fg `#1d2021` /
red `#ea6962` / orange `#e78a4e` / yellow `#d8a657` / green `#a9b665` /
aqua `#89b482` / purple `#d3869b` / grey `#928374`

## 5. 机器分流

`.chezmoiignore` 按 `.chezmoi.hostname`（= `uname -n`）ignore 整目录：
Niri-WM 只留 niri，Umbriel-WM 只留 umbriel。source 根的非管理文件
（Makefile、README.md、AGENTS.md 等）必须同步加进 `.chezmoiignore`，
否则会被当成 `~/` 目标文件。

## 6. 验证铁律

- 改模板必跑双主题 `chezmoi cat` 渲染 + TOML/语法校验；starship 改完必跑
  `STARSHIP_CONFIG=<render> starship prompt` 真加载。
- 纯重构（拆文件、改名）必须重构前后渲染 `diff` 为空（注释行改写除外）。
- 对比度：彩底上的字至少 4.5:1，算完再提交（`python3` 现算）。
- 跑完 `make <theme>` 切回来，保持工作区停在改动前的主题。
