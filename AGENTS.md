## AGENTS.md 文件保护与授权更新规则

`AGENTS.md` 是本项目的核心 AI 行为规范，必须视为受保护文件。

### 默认保护

- **禁止主动修改**：除非用户明确授权，否则不得对 `AGENTS.md` 进行任何修改。
- **禁止间接修改**：不得以整理文档、统一格式、修正措辞、更新规则、同步配置或重构项目为由，擅自修改 `AGENTS.md`。
- **禁止删除或替换**：不得删除、覆盖、重命名、移动或重新生成该文件。
- **禁止扩大修改范围**：即使任务涉及其他文档或配置，也不得顺带修改 `AGENTS.md`。
- **发现问题时先报告**：如果发现规则过时、冲突、遗漏或存在错误，应向用户说明具体位置和建议修改内容，等待用户明确授权。

### 授权更新

当用户新增软件、新增主题或调整现有配置架构，导致 `AGENTS.md` 需要补充规范时：

1. AI 可以主动分析现有规范是否需要更新，并提出修改建议。
2. AI 必须先向用户说明需要修改的章节、具体内容及原因。
3. **只有获得用户明确授权后，才能修改 `AGENTS.md`。**
4. 修改必须沿用现有文档的语言、结构、命名方式、格式和约定，保持整体一致性。
5. 优先采用增量修改，只修改与本次任务直接相关的章节，不得无故重写或整理其他内容。
6. 新增软件或主题时，应检查其与现有主题系统、色板规范、Chezmoi 分发机制及 just/Makefile 规则之间的关系。
7. 修改完成后，应向用户说明实际变更的章节和内容。

**默认不修改，主动提出建议，获得明确授权后才修改。**
---

# 1. 唯一主题开关

## 1.1 主题变量

整个项目只允许存在一个全局主题变量：

`theme`

合法值只有：

- `tokyonight`（默认）
- `gruvbox-dark`
- `gruvbox-light`

禁止为不同软件创建独立的主题开关。

例如：

- `kitty_theme`
- `niri_theme`
- `starship_theme`
- `noctalia_theme`

这些独立变量都不应该存在。

所有软件必须由同一个 `theme` 变量控制。

## 1.2 主题变量存放位置

持久化位置：

`~/.config/chezmoi/chezmoi.toml`

使用 `[data]` 下的 `theme`：

```toml
[data]
    theme = "tokyonight"
```

默认值定义在：

`.chezmoi.toml.tmpl`

默认主题必须为 `tokyonight`。

## 1.3 主题切换入口

主题切换统一使用 just：

```bash
just tokyonight
just gruvbox-dark
just gruvbox-light
```

其他入口：

```bash
just install
just reset
```

其中：

- `just install`：初次安装配置。
- `just reset`：恢复默认主题，等价于 `just tokyonight`。

当机器不支持当前 justfile 使用的语法时，使用 Makefile 兜底：

```bash
make tokyonight
make gruvbox-dark
make gruvbox-light

make install
make reset
```

两种入口必须具有相同的功能和行为。

## 1.4 临时主题覆盖

允许使用 Chezmoi 的临时数据覆盖：

```bash
chezmoi <cmd> --override-data '{"theme":"gruvbox-dark"}'
```

此操作只影响当前命令，不得修改持久化主题设置。

## 1.5 模板变量读取

模板中必须使用安全读取方式：

```gotemplate
{{ get . "theme" | default "tokyonight" }}
```

禁止直接使用：

```gotemplate
{{ .theme }}
```

原因是项目使用 `missingkey=error`，直接读取可能导致模板渲染失败。

## 1.6 非法主题处理

主题名称必须经过合法性检查。

允许值：

```text
tokyonight
gruvbox-dark
gruvbox-light
```

遇到非法主题名称时：

- 明确报错。
- 显示允许的主题名称。
- 停止当前操作。
- 不得静默回退到默认主题。

禁止使用默认分支掩盖拼写错误。

---

# 2. 主题统一性

这是整个项目最重要的约定。

**主题名称必须在所有受管理的软件中保持一致。**

新增主题时，只增加主题名称和对应的主题资源，不应为了新增主题而修改现有主题分发逻辑。

## 2.1 必须存在的主题资源

每个主题都必须按照以下结构提供对应文件。

| 软件 | 主题资源 |
|---|---|
| kitty | `.chezmoitemplates/kitty/<theme>.conf` |
| starship | `starship.toml` 的 `[palettes.<theme>]` |
| fcitx5 | `themes/<theme>/` |
| yazi | `flavors/<theme>.yazi/` |
| niri | `.chezmoitemplates/niri/<theme>.kdl` |
| bat | `themes/<theme>.tmTheme` |
| fuzzel | `.chezmoitemplates/fuzzel/<theme>.ini` |
| KDE | `.chezmoitemplates/kde/<theme>.colors` |
| Noctalia | `palettes/<theme>.json` |
| Zed | `settings.json` 中对应的原生主题名称 |

新增主题时必须检查所有上述资源。

不能出现某个软件仍然使用旧主题、默认主题或其他主题的情况。

## 2.2 新增主题的原则

例如新增一个主题：

`catppuccin-mocha`

需要完成：

1. 创建 kitty 主题文件。
2. 添加 Starship palette。
3. 添加 fcitx5 主题目录。
4. 添加 Yazi flavor。
5. 创建 Niri 主题文件。
6. 添加 bat tmTheme。
7. 创建 Fuzzel 主题文件。
8. 创建 KDE 色彩方案。
9. 创建 Noctalia palette。
10. 配置 Zed 对应的主题名称。
11. 更新主题合法值检查。
12. 确保 just 和 Makefile 都支持新主题。
13. 确保主题切换、安装和重置行为正常。

不得只完成部分软件的主题适配。

如果某个软件不支持该主题，必须明确说明原因，不得静默使用其他主题。

---

# 3. 各软件主题接线方式

优先使用软件原生主题支持。

只有软件不支持统一的主题机制时，才使用 Chezmoi 模板分发。

## 3.1 Kitty

使用动态模板分发：

```gotemplate
{{ includeTemplate (printf "kitty/%s.conf" (get . "theme" | default "tokyonight")) . }}
```

要求：

- 每个主题独立一个配置文件。
- 主配置文件只负责动态分发。
- 不要在主配置文件重复定义各主题的颜色。

## 3.2 Starship

使用 Starship 原生 palette：

```toml
[palettes.tokyonight]
...

[palettes.gruvbox-dark]
...

[palettes.gruvbox-light]
...
```

主配置只模板化：

```toml
palette = "{{ get . "theme" | default "tokyonight" }}"
```

不要为每个主题创建独立的 Starship 配置文件。

## 3.3 Fcitx5

每个主题提供独立目录：

```text
themes/
├── tokyonight/
├── gruvbox-dark/
└── gruvbox-light/
```

每个主题提供两份版本：

- 普通版本。
- Flatpak 兼容版本（不包含 SVG）。

`classicui.conf` 中使用：

```ini
Theme={{ get . "theme" | default "tokyonight" }}
```

重要限制：

- 禁止 SVG。
- 禁止透明色。
- 禁止 `fill-opacity < 1`。
- 优先使用纯色。
- 不要引入可能导致输入框整体发虚的透明效果。

过去出现过 `fill-opacity < 1` 导致整个输入框发虚的生产问题，禁止重复引入。

## 3.4 Yazi

使用独立 flavor：

```text
flavors/
├── tokyonight.yazi/
├── gruvbox-dark.yazi/
└── gruvbox-light.yazi/
```

`theme.toml` 中：

```toml
[flavor]
dark = "{{ get . "theme" | default "tokyonight" }}"
light = "{{ get . "theme" | default "tokyonight" }}"
```

根据统一主题变量选择 flavor，不要创建额外主题开关。

## 3.5 Niri

使用 `colour.kdl` 作为统一分发入口。

分发：

```text
.chezmoitemplates/niri/
├── tokyonight.kdl
├── gruvbox-dark.kdl
└── gruvbox-light.kdl
```

要求：

- 使用动态模板分发。
- 每个主题文件只保留一个 `layout` 块。
- 中性色值由各配置片段自行提供。
- 不要在多个文件重复定义主题颜色。
- 不要为新增主题修改分发逻辑。

## 3.6 Bat

使用独立 tmTheme：

```text
themes/
├── tokyonight.tmTheme
├── gruvbox-dark.tmTheme
└── gruvbox-light.tmTheme
```

要求：

- 内置 `name` 必须与主题变量完全一致。
- `config` 使用 `--theme={{ .theme }}`。
- 不要在 Bat 配置中硬编码固定主题。

新增主题或修改 tmTheme 后，需要在明确执行 Bat 缓存更新时运行：

```bash
bat cache --build
```

该操作已经纳入 justfile 的相关管理逻辑。

## 3.7 Fuzzel

使用独立模板：

```text
.chezmoitemplates/fuzzel/
├── tokyonight.ini
├── gruvbox-dark.ini
└── gruvbox-light.ini
```

通过 `fuzzel.ini` 分发。

主题文件只包含：

```ini
[colors]
```

主题无关配置放在主文件中：

```ini
[main]
font = ...
```

```ini
[border]
width = 5
radius = 0
```

要求：

- 字体与 Kitty 保持一致。
- `width=5`。
- `radius=0`。
- `border` 颜色与 Niri 的 focus-ring 保持一致。
- RGBA 使用小写，不带 `#`。
- 不要在各主题文件重复定义字体和边框布局。

## 3.8 Zed

使用 Zed 原生主题机制。

`settings.json` 中只需要模板化 `theme` 一行。

主题对应关系：

| 项目主题 | Zed 主题 |
|---|---|
| tokyonight | Tokyo Night |
| gruvbox-dark | Gruvbox Dark Hard |
| gruvbox-light | Gruvbox Light |

注意：

- `Tokyo Night` 使用已安装的扩展主题。
- Gruvbox 使用 Zed 内置主题。
- 浅色主题必须使用 `Gruvbox Light`，不是 `Gruvbox Light Hard`。
- `settings.json` 其他内容必须原样保留。
- Zed 插件位于 Zed 自己的数据目录，不由 Chezmoi 管理。

## 3.9 KDE

使用独立主题文件：

```text
.chezmoitemplates/kde/
├── tokyonight.colors
├── gruvbox-dark.colors
└── gruvbox-light.colors
```

通过 `private_kdeglobals` 分发到：

`~/.config/kdeglobals`

同时安装到：

`~/.local/share/color-schemes/<theme>.colors`

要求：

- 使用完整 KDE 色彩方案。
- 包含 `[General]`。
- `[Colors:Header][Inactive]` 必须与 `[Colors:Header]` 完全一致。
- `[WM]` inactive 必须与 active 完全一致。
- `ColorEffects:Inactive` 关闭。
- 不允许窗口失焦后产生意外的颜色变化。

KDE 主题与 Noctalia 的 KDE 色彩方案机制分离。

不要将 KDE 色彩方案交给 Noctalia 的 `kcolorscheme` 管理。

## 3.10 Noctalia

使用 Noctalia 原生 palette：

```text
palettes/
├── tokyonight.json
├── gruvbox-dark.json
└── gruvbox-light.json
```

使用 v2 格式：

- 顶层 `version: 2`。
- 使用 role 名称作为颜色键。
- 只写 `dark`。
- `light` 缺省时回落到 dark。

通过 `setting.toml` 选择：

```toml
source = "custom"
custom_palette = "{{ get . "theme" | default "tokyonight" }}"
mode = "{{ if contains "light" (get . "theme" | default "tokyonight") }}light{{ else }}dark{{ end }}"
shell_mode = "follow"
```

浅色模式规则：

- 主题名称包含 `light` 时使用 `light`。
- 其他主题使用 `dark`。
- 不得将 `mode` 永久写死为 `dark`。

原因：

Noctalia 的 `dark` 和 `light` 是两套独立的派生公式。浅色色值放进 dark 分支可能被处理成深色。

### Shell 配置

固定：

```toml
[shell]
app_icon_color = "on_surface_variant"
```

使用角色名称引用，让颜色自动跟随主题。

### 图标着色

Noctalia v5.5 起，各组件使用自己的：

```toml
colorize_icons = true
```

适用组件：

- audio
- dock
- notification
- launcher
- window_switcher
- taskbar
- workspaces
- tray
- active_window
- widget

另外：

- `polkit_colorize_icons`
- `screen_time_colorize_icons`

旧版 `app_icon_colorize` 已移除，不得继续使用。

### 其他约束

- `builtin_ids` 只保留 gtk3、gtk4、qt。
- `community_ids` 保持为空。
- KDE 色彩方案使用独立 KDE 分发机制。
- Noctalia 不得重新生成 Kitty、Niri、Yazi、Fcitx5、Starship 的配置文件。

避免多个软件同时管理同一份配置，造成配置冲突。

---

# 4. 色板管理

## 4.1 唯一色板真源

以下颜色是当前项目的基础色板。

修改主题颜色时，先修改这里，再同步到所有相关软件。

不要只修改某个软件的颜色而忽略其他软件。

### Tokyo Night

```text
surface   #212736
fg        #e3e5e5
blue      #769ff0
panel     #394260
time_bg   #1d2230
os_bg     #a3aed2
os_fg     #090c0c

red       #f7768e
green     #9ece6a
yellow    #e0af68
purple    #bb9af7
cyan      #7dcfff
orange    #ff9e64
grey      #545c7e
```

### Gruvbox Dark

基于 gruvbox-material：

```text
style       dark
background  hard
foreground  material

surface     #282828
fg          #ddc7a1
blue        #7daea3
panel       #32302f
bg3         #3c3836

time_bg     #141617
os_bg       #d8a657
os_fg       #1d2021

red         #ea6962
orange      #e78a4e
yellow      #d8a657
green       #a9b665
aqua        #89b482
purple      #d3869b
grey        #928374
```

### Gruvbox Light

基于 gruvbox-material：

```text
style       light
background  hard
foreground  material

surface     #f5edca
fg          #4f3829
blue        #45707a
panel       #f3eac7
bg3         #f2e5bc

time_bg     #f3eac7
os_bg       #654735
os_fg       #f9f5d7

red         #c14a4a
orange      #c35e0a
yellow      #b47109
green       #6c782e
aqua        #4c7a5d
purple      #945e80
grey        #928374
```

## 4.2 软件特定颜色

以下颜色存在特定用途，不要直接用基础 surface 替代。

### Kitty Background

```text
tokyonight   #1a1b26
gruvbox-dark #1d2021
gruvbox-light #fbf1c7
```

### Noctalia Surface

Noctalia 顶栏的 `surface` 必须跟随 Kitty 的 `background`，而不是上面定义的通用 `surface`。

### Umbriel Unfocused

两个 Gruvbox 主题使用透明 unfocused：

```text
gruvbox-dark  #1d202100
gruvbox-light #f9f5d700
```

### OS Background

不要直接使用 yellow 作为 `os_bg`。

原因：

`#b47109` 配深色或浅色文字的对比度分别约为 2.75 和 3.59，均低于 4.5:1。

Gruvbox Light 使用：

```text
os_bg #654735
os_fg #f9f5d7
```

对比度约为 7.61:1。

### Noctalia Primary

Gruvbox Light 使用：

```text
primary #45707a
secondary #4c7a5d
error #c14a4a
```

这些颜色属于经过对比度检查的浅色主题配色。

Secondary 和 Error 属于接近上游浅色方案的对比度边界，修改时需要重新检查。

## 4.3 KDE 颜色映射

KDE 主题使用以下映射：

| KDE 角色 | 对应颜色 |
|---|---|
| bg_view | Kitty background |
| bg_window | surface |
| bg_header | time_bg |
| bg_button | bg3 |
| selection | accent + os_fg |

特殊处理：

- Tokyo Night 的 `bg_button` 使用 `panel`。
- 两个 Gruvbox 主题的 inactive header 必须与 active 完全相同。
- 两个 Gruvbox 主题的 inactive WM 必须与 active 完全相同。

## 4.4 对比度

彩色背景上的文字应尽量满足 WCAG AA：

```text
普通文字：至少 4.5:1
大号文字：至少 3:1
```

涉及颜色修改时，应使用 Python 重新计算实际对比度。

不要凭视觉判断对比度是否合格。

---

# 5. 机器分流

`.chezmoiignore` 根据 `XDG_CURRENT_DESKTOP` 分流。

使用：

```gotemplate
{{ env "XDG_CURRENT_DESKTOP" | lower }}
```

规则：

- 包含 `niri`：只保留 Niri 配置。
- 包含 `umbriel`：只保留 Umbriel 配置。
- 不属于上述环境时，按照现有默认分流逻辑处理。

不要将 Niri 和 Umbriel 的专属配置同时分发到同一台机器。

## 5.1 Source 根目录文件

Source 根目录中不应该被部署到用户 HOME 的普通文件，也必须加入 `.chezmoiignore`。

例如：

```text
README.md
AGENTS.md
```

否则 Chezmoi 可能将这些文件错误地当成 HOME 目标文件。

新增项目说明文件时，也要检查是否需要加入忽略列表。

---

# 6. just 与 Makefile 同步

这是项目的重要兼容性要求。

## 6.1 just 是主要入口

正常机器优先使用 just：

```bash
just install
just reset
just tokyonight
just gruvbox-dark
just gruvbox-light
just fcitx5
just ibus
```

justfile 是主要开发和维护入口。

新功能优先在 justfile 中设计，然后同步实现到 Makefile。

## 6.2 Makefile 是独立兜底

由于部分旧机器存在 just 版本过旧的问题：

- 可能不支持 `[group]`。
- 可能不支持当前 justfile 使用的其他语法。
- 某些发行版仓库可能根本没有 just。

因此必须提供 Makefile 作为独立备用入口。

旧机器可以直接执行：

```bash
make install
make reset
make tokyonight
make gruvbox-dark
make gruvbox-light
make fcitx5
make ibus
```

不需要安装或调用 just。

## 6.3 严禁 Makefile 调用 just

**Makefile 必须使用 GNU Make 原生语法重新实现 justfile 的功能。**

禁止以下做法：

```makefile
install:
	just install
```

禁止：

```makefile
%:
	just $@
```

禁止任何通过 Shell、脚本或其他间接方式调用 just 的兼容实现。

原因：

旧机器使用 Makefile 就是为了绕过旧版本 just 的语法和功能限制。

如果 Makefile 仍然依赖 just，就失去了兼容意义。

## 6.4 双向功能一致

修改 justfile 的任何 recipe，都必须同步更新 Makefile。

两者需要保持：

- 目标名称一致。
- 执行行为一致。
- 参数和默认值一致。
- 主题合法性检查一致。
- 错误处理一致。
- 提示信息一致。
- 配置写入位置一致。
- 热加载行为一致。

注意：

这里的同步是功能同步，不是语法同步。

justfile 使用 Just 语法。

Makefile 使用 GNU Make 语法。

不要为了统一代码而强行使用同一种语法。

## 6.5 原生语法实现

Makefile 必须独立实现对应操作。

例如：

justfile：

```just
[group('theme')]
tokyonight:
    # theme implementation

[group('theme')]
gruvbox-dark:
    # theme implementation
```

Makefile：

```makefile
.PHONY: tokyonight gruvbox-dark

tokyonight:
	# GNU Make compatible implementation

gruvbox-dark:
	# GNU Make compatible implementation
```

以上只是结构示例，实际实现应根据现有 recipe 编写。

Makefile 不得依赖 just 的：

- Recipe 调用机制。
- 模板语法。
- `[group]`。
- Just 专用变量。
- Just 专用函数。

## 6.6 目标名称与行为映射

| 功能 | justfile | Makefile |
|---|---|---|
| 默认帮助 | just 默认帮助 | make 默认 help |
| 初次安装 | install | install |
| 重置主题 | reset | reset |
| Tokyo Night | tokyonight | tokyonight |
| Gruvbox Dark | gruvbox-dark | gruvbox-dark |
| Gruvbox Light | gruvbox-light | gruvbox-light |
| 切换 Fcitx5 | fcitx5 | fcitx5 |
| 切换 IBus | ibus | ibus |
| 应用主题 | apply-theme | _apply-theme |
| 写入输入法 | write-im | _write-im |

`apply-theme` 和 `write-im` 是内部辅助目标，对应 Makefile 中的 `_apply-theme` 和 `_write-im`。

内部目标可以使用 `.PHONY` 和其他 GNU Make 机制处理。

## 6.7 默认帮助

Makefile 默认目标必须为：

```makefile
.DEFAULT_GOAL := help
```

`make` 不带参数时显示可用目标。

just 继续使用：

```just
[group("theme")]
```

等 Just 原生分组机制。

两者的帮助展示方式可以不同，但公开目标和功能必须一致。

## 6.8 依赖与兼容性

Makefile 应尽量使用老版本 GNU Make 和常见 POSIX 工具支持的语法。

避免不必要的新特性。

不要为了让 Makefile 更像 justfile 而引入额外依赖。

目标是让没有可用 just 的旧机器也能够完成安装、主题切换和输入法配置。

## 6.9 修改后的同步检查

每次修改 justfile 后，检查：

1. 是否存在新增或删除的 recipe。
2. 是否同步修改 Makefile。
3. 两者的目标名称是否一致。
4. 两者执行的操作是否一致。
5. 是否意外在 Makefile 中调用 just。
6. 旧机器能否仅依赖 GNU Make 执行对应功能。

不要只同步目标名称而忽略实际执行行为。

---

# 7. 主题切换与热加载

`just <theme>` 和 `make <theme>` 必须实现相同的主题切换流程。

基本行为：

1. 检查主题名称是否合法。
2. 更新持久化 `theme` 变量。
3. 执行 Chezmoi 配置分发。
4. 按需触发相关软件热加载。
5. 提示切换结果。

## 7.1 热加载

主题切换后，根据当前机器实际运行的软件执行热加载。

### Fcitx5

使用：

```bash
busctl ... ReloadAddonConfig
```

### Niri

使用：

```bash
niri msg action load-config-file
```

### Umbriel

使用：

```bash
umbriel msg config-reload
```

### Noctalia

使用：

```bash
noctalia msg config-reload
```

四个命令均使用容错方式：

```bash
command || true
```

要求：

- 对应软件没有安装时，不影响主题切换。
- 当前没有运行 compositor 时，不影响主题切换。
- 不应因为热加载失败而回滚已经写入的主题设置。
- 不要在非必要情况下重启整个桌面环境。

justfile 和 Makefile 必须保持相同的热加载行为。

---

# 8. 输入法开关

`just fcitx5`、`just ibus` 以及对应的 Makefile 目标，只负责写入输入法环境变量。

不要在这些目标中额外实现输入法自启动、服务管理或桌面环境配置。

自启动仍然由 Niri/Umbriel 的 autostart 管理。

## 8.1 环境变量

文件：

`~/.config/environment.d/im.conf`

需要设置：

- `QT_IM_MODULES=wayland;<mod>`
- `QT_IM_MODULE`
- `XMODIFIERS=@im=<mod>`
- `SDL_IM_MODULE`

其中：

```text
fcitx5 -> mod=fcitx
ibus   -> mod=ibus
```

## 8.2 GTK 特殊处理

**不要设置全局 `GTK_IM_MODULE`。**

Wayland 下设置该变量可能导致输入法异常。

Xwayland GTK 使用：

`~/.config/gtk-3.0/settings.ini`

其中：

```ini
gtk-im-module=<mod>
```

## 8.3 Flatpak

Flatpak 无法直接读取上述 GTK settings.ini 配置时，使用用户级 override：

```bash
flatpak override --user \
  --env=GTK_IM_MODULE=<mod> \
  --env=QT_IM_MODULE=<mod>
```

不要在普通输入法切换目标中擅自执行 Flatpak 全局修改，除非当前任务明确涉及该操作。

## 8.4 生效条件

环境变量修改后，需要重新登录才能完全生效。

切换输入法时应明确提示这一点。

---

# 9. 配置修改原则

## 9.1 保持现有架构

修改配置前，先了解现有 Chezmoi 文件结构和模板分发关系。

不要随意改变：

- Source 目录结构。
- 模板分发机制。
- 主题变量名称。
- 软件主题接线方式。
- 机器分流规则。
- just/Makefile 的目标关系。

优先进行最小化修改。

## 9.2 避免重复管理

一个配置文件只能有一个明确的管理来源。

例如：

- Noctalia 不负责重新生成 Kitty 配置。
- Noctalia 不负责重新生成 Niri 配置。
- KDE 色彩方案由 KDE 分发机制管理。
- Starship 使用自身的 palette 机制。

不要让多个程序或模板同时管理同一配置文件。

## 9.3 尊重软件原生能力

如果软件已经支持原生多主题：

优先使用原生机制。

例如：

- Starship：原生 palettes。
- Zed：原生 theme。
- Noctalia：原生 custom palette。

如果软件没有合适的原生主题机制，再使用 Chezmoi 模板分发。

## 9.4 新增软件

新增软件主题支持时：

1. 确认该软件是否支持原生主题。
2. 确认主题配置文件位置。
3. 使用统一的 `theme` 变量。
4. 复用现有色板。
5. 不创建独立主题开关。
6. 检查深色和浅色模式。
7. 检查是否与其他软件发生配置冲突。
8. 确保新增主题时不会破坏现有主题。

---

# 10. 修改与验证

主题系统的修改应注重一致性，而不是只确保单个软件能够正常运行。

## 10.1 修改前

修改前应：

- 阅读相关配置文件。
- 理解主题分发方式。
- 确认变量来源。
- 检查是否存在重复配置。
- 确认 justfile 和 Makefile 的关联目标。

涉及软件行为、配置格式或上游功能时，优先查阅对应软件的官方文档和上游实现。

## 10.2 修改后

根据修改范围进行适当检查。

主题模板修改时，重点检查：

- 三个主题是否都能正确渲染。
- 是否存在非法主题回退。
- 所有软件的主题名称是否一致。
- 色板是否同步。
- 深色与浅色模式是否正确。
- 是否产生重复管理的配置文件。

justfile 修改时，重点检查：

- Makefile 是否同步。
- Makefile 是否独立实现。
- 是否意外调用 just。
- 两者功能是否一致。

纯重构（拆文件、改名）时，尽量比较修改前后的 Chezmoi 渲染结果，确保没有非预期差异。

## 10.3 主题切换验证

需要验证时，可以检查：

```bash
chezmoi cat <target>
```

分别检查：

```text
tokyonight
gruvbox-dark
gruvbox-light
```

确保每个主题都能正确生成配置。

Starship 变更需要时，使用实际渲染结果进行加载检查。

## 10.4 工作区状态

执行主题切换测试时，应注意不要意外改变用户当前使用的主题。

如果测试需要切换主题，完成后应恢复测试前的主题。

不要擅自覆盖用户原有的主题设置。

---

# 11. 文件管理约定

以下文件不应该被 Chezmoi 当作 HOME 目标文件分发：

```text
README.md
AGENTS.md
justfile
Makefile
```

确保它们在 `.chezmoiignore` 中正确处理。

新增根目录开发文件时，检查是否需要加入忽略规则。

---

# 12. 最终原则

1. 整个项目只允许一个主题变量：`theme`。
2. 所有软件必须遵循统一的主题名称。
3. 新增主题必须检查所有受管理的软件。
4. 色板是唯一真源，修改后同步所有相关配置。
5. 优先使用软件原生主题机制。
6. 不支持原生主题的软件使用 Chezmoi 模板分发。
7. 非法主题名称必须明确报错，不允许静默回退。
8. just 是主要入口。
9. Makefile 是独立兼容入口，不依赖 just。
10. 修改 justfile 的 recipe 必须同步实现到 Makefile。
11. 两者同步的是功能和行为，不是语法。
12. Makefile 必须使用 GNU Make 原生语法。
13. Niri 和 Umbriel 配置必须正确分流。
14. 不允许多个软件同时管理同一配置文件。
15. 修改主题时必须考虑深色、浅色以及对比度。
16. 保持现有配置架构，避免无必要的重构。

**核心目标：统一主题、统一行为、减少重复配置，并确保新旧机器都能可靠管理 Dotfiles。**
