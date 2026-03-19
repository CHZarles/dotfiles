# Neovim 配置中文使用手册

## 1. 手册说明

这份手册基于当前仓库中的研究文档和现有配置编写，目标是帮助你从“使用者”角度理解并使用这套 Neovim 配置。内容只描述当前已经存在的行为、快捷键和工作流，不扩展到未配置的功能。

相关研究文档：`research/codebase-state-2026-03-19.md:1-99`

---

## 2. 这套配置的整体结构

这套配置的启动入口是 `init.lua`，启动顺序是：

1. 先加载核心配置
2. 再加载 Lazy.nvim
3. 由 Lazy.nvim 导入普通插件和 LSP 插件

对应代码：
- `init.lua:1-2`
- `lua/josean/core/init.lua:1-2`
- `lua/josean/lazy.lua:1-22`

从使用者角度看，可以把它理解为三层：

- **基础编辑行为**：行号、缩进、分屏、标签页、基础快捷键
- **日常编辑工具**：文件搜索、文件树、终端、注释、替换、Git、诊断、待办、翻译等
- **语言开发能力**：LSP、自动补全、格式化、Lint

---

## 3. 默认编辑行为

### 3.1 基础选项

这套配置默认启用了以下行为：

- 显示绝对行号和相对行号
- 使用 2 空格缩进
- Tab 会展开为空格
- 不自动换行
- 搜索时启用 `ignorecase + smartcase`
- 高亮当前行
- 使用真彩色，背景为深色
- 始终显示 sign column
- 使用系统剪贴板 `unnamedplus`
- 垂直分屏默认在右侧打开
- 水平分屏默认在下方打开
- 关闭 swapfile

对应代码：`lua/josean/core/options.lua:1-39`

### 3.2 Leader 键

这套配置的 `<leader>` 是空格键。

对应代码：`lua/josean/core/keymaps.lua:1`

---

## 4. 启动界面与首次进入

启动 Neovim 时会进入 Alpha 仪表盘界面。这个界面提供以下入口：

- `e`：新建文件
- `SPC ff`：查找文件
- `SPC fs`：全文搜索
- `SPC wr`：恢复当前目录会话
- `q`：退出 Neovim

对应代码：`lua/josean/plugins/alpha.lua:3-49`

如果你平时是从某个项目目录启动 Neovim，那么这个首页可以作为进入工作区的起点。

---

## 5. 核心快捷键总览

### 5.1 插入模式

- `jk`：退出插入模式

对应代码：`lua/josean/core/keymaps.lua:5`

### 5.2 搜索与数字操作

- `<leader>nh`：清除搜索高亮
- `<leader>+`：对光标下数字执行加一
- `<leader>-`：对光标下数字执行减一

对应代码：`lua/josean/core/keymaps.lua:7-11`

### 5.3 分屏操作

- `<leader>sv`：垂直分屏
- `<leader>sh`：水平分屏
- `<leader>se`：让所有分屏等宽等高
- `<leader>sx`：关闭当前分屏
- `<leader>sm`：最大化 / 还原当前分屏

对应代码：
- `lua/josean/core/keymaps.lua:13-17`
- `lua/josean/plugins/vim-maximizer.lua:1-6`

### 5.4 标签页操作

- `<leader>to`：新建标签页
- `<leader>tx`：关闭当前标签页
- `<leader>tn`：切换到下一个标签页
- `<leader>tp`：切换到上一个标签页
- `<leader>tf`：把当前 buffer 在新标签页中打开

对应代码：`lua/josean/core/keymaps.lua:19-23`

---

## 6. 文件浏览与项目导航

这套配置当前以 **Oil** 作为默认文件浏览器；当 Neovim 版本低于 0.12 时，会启用 `nvim-tree` 作为替代实现。

对应代码：
- `lua/josean/plugins/oil.lua:8-195`
- `lua/josean/plugins/nvim-tree.lua:1-57`

### 6.1 打开文件浏览器

在当前配置下，常用方式是：

- `-`：打开父目录
- `<leader>ee`：打开文件浏览器
- `<leader>ef`：以浮窗方式打开文件浏览器

对应代码：`lua/josean/plugins/oil.lua:191-195`

### 6.2 Oil 缓冲区中的常用键

进入 Oil 后，常用按键如下：

- `<CR>`：打开选中项
- `<C-s>`：在垂直分屏中打开
- `<C-h>`：在水平分屏中打开
- `<C-t>`：在新标签页中打开
- `<C-p>`：预览
- `<C-c>`：关闭 Oil
- `<C-l>`：刷新
- `-`：回到上级目录
- `_`：打开当前工作目录
- `cd`：切换当前目录
- `gs`：切换排序方式
- `gx`：用外部程序打开
- `g.`：切换隐藏文件显示
- `g\\`：切换 trash 视图
- `g?`：显示帮助

对应代码：`lua/josean/plugins/oil.lua:66-83`

### 6.3 Oil 的显示行为

当前 Oil 配置还包括：

- 默认隐藏以 `.` 开头的文件
- 可以通过 `g.` 显示或隐藏隐藏文件
- 默认按类型、再按名称排序
- 不自动监控文件系统变化
- 删除文件不会送入回收站

对应代码：`lua/josean/plugins/oil.lua:37-59,86-123`

### 6.4 nvim-tree 的备用快捷键

如果当前环境启用了 `nvim-tree`，则还会有以下快捷键：

- `<leader>ee`：切换文件树
- `<leader>ef`：在文件树中定位当前文件
- `<leader>ec`：折叠文件树
- `<leader>er`：刷新文件树

对应代码：`lua/josean/plugins/nvim-tree.lua:52-55`

---

## 7. 搜索、跳转与定位

### 7.1 Telescope 搜索

Telescope 提供项目搜索的主入口：

- `<leader>ff`：搜索当前目录文件
- `<leader>fr`：搜索最近打开的文件
- `<leader>fs`：全文搜索
- `<leader>fc`：搜索光标下单词
- `<leader>ft`：搜索 TODO 注释

对应代码：`lua/josean/plugins/telescope.lua:41-48`

在 Telescope 界面中：

- `<C-k>`：上一项
- `<C-j>`：下一项
- `<C-q>`：把结果发送到 quickfix，并打开 Trouble 的 quickfix 视图
- `<C-t>`：在 Trouble 中打开 Telescope 结果

对应代码：`lua/josean/plugins/telescope.lua:25-37`

### 7.2 Hop 快速跳转

- `<leader>h`：触发 `HopWord`，在当前窗口内快速跳转到单词

对应代码：`lua/josean/plugins/hop.lua:7-11`

---

## 8. 会话与工作区

当前配置启用了 `auto-session`，但**不会自动恢复会话**，需要手动操作。

常用快捷键：

- `<leader>wr`：恢复当前工作目录的会话
- `<leader>ws`：保存当前工作目录的会话

对应代码：`lua/josean/plugins/auto-session.lua:6-14`

Alpha 首页中的 “Restore Session For Current Directory” 按钮也是调用 `SessionRestore`。

对应代码：`lua/josean/plugins/alpha.lua:35-41`

---

## 9. 终端使用

这套配置使用 `toggleterm.nvim` 提供内置终端。

### 9.1 打开终端

- `<C-\\>`：打开或切换浮动终端

对应代码：`lua/josean/plugins/toggleterm.lua:7-13`

### 9.2 终端中的行为

- 新终端打开后默认进入插入模式
- 终端窗口采用浮动窗口
- 在终端模式中按 `<Esc>` 会退出到普通模式

对应代码：`lua/josean/plugins/toggleterm.lua:8-14`

---

## 10. 编辑增强功能

### 10.1 注释

配置启用了 `Comment.nvim` 并结合 `nvim-ts-context-commentstring`。这表示注释行为会根据 Tree-sitter 上下文决定注释风格。

对应代码：`lua/josean/plugins/comment.lua:1-19`

### 10.2 自动配对

插入模式下启用 `nvim-autopairs`，会自动处理成对符号，同时和补全确认动作联动。

对应代码：`lua/josean/plugins/autopairs.lua:1-31`

### 10.3 替换操作

当前配置把 `substitute.nvim` 绑定到了 `s` 系列按键：

- `s`：按 motion 执行替换
- `ss`：替换整行
- `S`：从光标替换到行尾
- 可视模式下 `s`：替换选区

对应代码：`lua/josean/plugins/substitute.lua:12-15`

### 10.4 包围符编辑

启用了 `nvim-surround`，用于括号、引号、标签等包围符操作。

对应代码：`lua/josean/plugins/surround.lua:1-16`

---

## 11. Tree-sitter 与语法结构编辑

### 11.1 基础能力

当前配置启用了：

- Tree-sitter 语法高亮
- 基于 Tree-sitter 的缩进
- 标签自动闭合
- 增量选择

对应代码：`lua/josean/plugins/treesitter.lua:13-56`

### 11.2 增量选择

- `<C-space>`：初始化选择 / 扩大选择范围
- `<bs>`：缩小选择范围

对应代码：`lua/josean/plugins/treesitter.lua:47-54`

### 11.3 文本对象选择

启用了 `nvim-treesitter-textobjects`，可以按语义单位选中代码结构。当前配置中已有以下族群：

- 赋值：`a=` `i=` `l=` `r=`
- 对象属性：`a:` `i:` `l:` `r:`
- 参数：`aa` `ia`
- 条件块：`ai` `ii`
- 循环：`al` `il`
- 函数调用：`af` `if`
- 函数 / 方法定义：`am` `im`
- 类：`ac` `ic`

对应代码：`lua/josean/plugins/nvim-treesitter-text-objects.lua:14-44`

### 11.4 文本对象移动与交换

当前配置还包含：

- 参数、属性、函数的前后交换
- 函数调用、函数定义、类、条件、循环的前后跳转
- `;` / `,` 重复上一次结构移动
- `f/F/t/T` 也被接入可重复移动逻辑

对应代码：`lua/josean/plugins/nvim-treesitter-text-objects.lua:46-109`

---

## 12. 代码补全

补全由 `nvim-cmp` 提供，在插入模式进入时启用。

### 12.1 补全来源

当前补全来源包括：

- LSP
- LuaSnip
- 当前 buffer
- 文件路径

对应代码：`lua/josean/plugins/nvim-cmp.lua:46-55`

### 12.2 补全快捷键

在补全面板中：

- `<C-k>`：上一项
- `<C-j>`：下一项
- `<C-b>`：向上滚动文档
- `<C-f>`：向下滚动文档
- `<C-Space>`：手动触发补全
- `<C-e>`：取消补全
- `<CR>`：确认当前候选项

对应代码：`lua/josean/plugins/nvim-cmp.lua:37-45`

补全菜单使用 `lspkind` 显示图标，snippet 由 `LuaSnip` 展开。

对应代码：`lua/josean/plugins/nvim-cmp.lua:32-35,57-63`

---

## 13. LSP 使用手册

LSP 在打开文件时按文件类型加载，当前配置中已设置的服务器包括：

- `pyright`
- `svelte`
- `graphql`
- `emmet_ls`
- `lua_ls`

对应代码：`lua/josean/plugins/lsp/lspconfig.lua:75-126`

### 13.1 LSP 常用快捷键

这些快捷键在语言服务器附加到当前 buffer 后可用：

- `gR`：查看引用
- `gD`：跳转到声明
- `gd`：查看定义
- `gi`：查看实现
- `gt`：查看类型定义
- `<leader>ca`：代码动作
- `<leader>rn`：重命名
- `<leader>D`：当前文件诊断列表
- `<leader>d`：当前行诊断浮窗
- `[d`：上一条诊断
- `]d`：下一条诊断
- `K`：查看光标下文档说明
- `<leader>rs`：重启 LSP

对应代码：`lua/josean/plugins/lsp/lspconfig.lua:15-60`

### 13.2 当前 LSP 的一些具体行为

- Python LSP 使用当前环境里的 `python3` 路径
- Svelte 在保存 `*.js` / `*.ts` 文件后会通知 Svelte 服务刷新相关文件变化
- Lua LSP 把 `vim` 识别为全局变量

对应代码：
- `lua/josean/plugins/lsp/lspconfig.lua:87-94`
- `lua/josean/plugins/lsp/lspconfig.lua:96-105`
- `lua/josean/plugins/lsp/lspconfig.lua:115-126`

---

## 14. 格式化与检查

### 14.1 自动格式化

当前配置使用 `conform.nvim`，并启用了保存时自动格式化。

对应代码：`lua/josean/plugins/formatting.lua:7-29`

### 14.2 手动格式化

- `<leader>mp`：格式化当前文件，或在可视模式下格式化选区

对应代码：`lua/josean/plugins/formatting.lua:31-37`

### 14.3 当前文件类型对应的格式化工具

- JavaScript / TypeScript / React / Svelte / CSS / HTML / JSON / YAML / Markdown / GraphQL / Liquid：`prettier`
- Lua：`stylua`
- Python：`isort` + `black`

对应代码：`lua/josean/plugins/formatting.lua:8-23`

### 14.4 Lint

当前配置使用 `nvim-lint`，会在以下时机触发：

- 进入 buffer
- 写入文件后
- 离开插入模式时

对应代码：`lua/josean/plugins/linting.lua:16-23`

### 14.5 手动触发 Lint

- `<leader>l`：手动执行当前文件 lint

对应代码：`lua/josean/plugins/linting.lua:25-27`

### 14.6 当前文件类型对应的 Linter

- JavaScript / TypeScript / React / Svelte：`eslint_d`
- Python：`pylint`

对应代码：`lua/josean/plugins/linting.lua:7-14`

---

## 15. 诊断、问题列表与 TODO 管理

### 15.1 Trouble

当前配置使用 Trouble 作为诊断、quickfix、loclist 与 TODO 的集中查看界面。

快捷键如下：

- `<leader>xw`：工作区诊断
- `<leader>xd`：当前文档诊断
- `<leader>xq`：quickfix 列表
- `<leader>xl`：location list
- `<leader>xt`：TODO 列表

对应代码：`lua/josean/plugins/trouble.lua:7-14`

### 15.2 TODO 注释

`todo-comments.nvim` 识别的关键词包括：

- `FIX`
- `TODO`
- `HACK`
- `WARN`
- `PERF`
- `NOTE`
- `TEST`

对应代码：`lua/josean/plugins/todo-comments.lua:22-36`

跳转快捷键：

- `]t`：下一个 TODO 注释
- `[t`：上一个 TODO 注释

对应代码：`lua/josean/plugins/todo-comments.lua:11-17`

另外，`<leader>ft` 会通过 Telescope 搜索 TODO，`<leader>xt` 会通过 Trouble 展示 TODO。

对应代码：
- `lua/josean/plugins/telescope.lua:44-48`
- `lua/josean/plugins/trouble.lua:8-14`

---

## 16. Git 工作流

### 16.1 Gitsigns

当前配置为单文件 Git 变更提供了较完整的快捷键：

- `]h`：下一个 hunk
- `[h`：上一个 hunk
- `<leader>hs`：stage hunk
- `<leader>hr`：reset hunk
- 可视模式下 `<leader>hs`：stage 选区 hunk
- 可视模式下 `<leader>hr`：reset 选区 hunk
- `<leader>hS`：stage 整个 buffer
- `<leader>hR`：reset 整个 buffer
- `<leader>hu`：撤销 stage hunk
- `<leader>hp`：预览 hunk
- `<leader>hb`：查看当前行 blame
- `<leader>hB`：切换当前行 blame
- `<leader>hd`：和索引对比 diff
- `<leader>hD`：和 `~` 对比 diff
- `ih`：把 hunk 当作文本对象

对应代码：`lua/josean/plugins/gitsigns.lua:12-44`

### 16.2 Neogit

启用了 `neogit`，使用默认配置加载。

对应代码：`lua/josean/plugins/neogit.lua:1-13`

---

## 17. 辅助工具

### 17.1 翻译插件

`Trans.nvim` 提供翻译能力，当前快捷键为：

- `mm`：翻译
- `mk`：自动朗读 / 播放

普通模式和可视模式都可用。

对应代码：`lua/josean/plugins/trans.lua:6-13`

---

## 18. Markdown 使用

Markdown 文件现在使用内嵌渲染插件 `markview.nvim`，可直接在 Neovim 缓冲区中显示渲染后的 Markdown / LaTeX 数学内容。

可用命令包括：

- `:Markview toggle`
- `:Markview disable`
- `:Markview splitToggle`

默认快捷键包括：

- `<leader>mt`：切换当前缓冲区的 Markdown 预览
- `<leader>ms`：关闭当前缓冲区的 Markdown 预览

数学公式渲染依赖 `latex` Tree-sitter 解析器。

对应代码：`lua/josean/plugins/markdown-render.lua:1-8`、`lua/josean/plugins/treesitter.lua:24-47`

---

## 19. 界面外观

### 19.1 主题

当前启用的是 `gruvbox`，并在配置加载后执行：

- `vim.cmd("colorscheme gruvbox")`

对应代码：`lua/josean/plugins/colorscheme.lua:103-130`

### 19.2 状态栏和标签页

- `lualine.nvim` 提供状态栏
- `bufferline.nvim` 当前工作在 `tabs` 模式

对应代码：
- `lua/josean/plugins/lualine.lua:1-73`
- `lua/josean/plugins/bufferline.lua:1-10`

### 19.3 Which-key

启用了 `which-key.nvim`，超时时间是 500ms，这意味着按下 `<leader>` 后会较快显示按键提示。

对应代码：`lua/josean/plugins/which-key.lua:1-13`

---

## 20. 当前已配置语言与工具范围

从 Tree-sitter、LSP、格式化和 Lint 的组合来看，这套配置当前重点覆盖以下语言或文件类型：

- Lua
- Python
- JavaScript
- TypeScript
- TSX / React
- Svelte
- GraphQL
- HTML / CSS
- JSON / YAML
- Markdown
- Liquid

对应代码：
- `lua/josean/plugins/treesitter.lua:24-46`
- `lua/josean/plugins/lsp/lspconfig.lua:87-126`
- `lua/josean/plugins/formatting.lua:8-23`
- `lua/josean/plugins/linting.lua:7-14`

---

## 21. 推荐的日常使用路径（基于当前配置）

下面不是新增建议，而是把当前已有功能整理成一条更容易理解的使用路径：

### 场景 A：打开项目开始工作

1. 在项目目录启动 `nvim`
2. 进入 Alpha 首页
3. 用 `SPC ff` 找文件，或 `SPC wr` 恢复会话
4. 用 `-` 或 `SPC ee` 打开 Oil 浏览目录

对应代码：
- `lua/josean/plugins/alpha.lua:35-41`
- `lua/josean/plugins/oil.lua:191-195`

### 场景 B：查找内容并定位问题

1. `SPC fs` 全局搜索
2. `gd` / `gR` / `gi` / `gt` 做 LSP 跳转
3. `SPC d` 查看行诊断，`SPC D` 查看 buffer 诊断
4. `SPC xw` 或 `SPC xd` 打开 Trouble 看问题列表

对应代码：
- `lua/josean/plugins/telescope.lua:44-47`
- `lua/josean/plugins/lsp/lspconfig.lua:23-60`
- `lua/josean/plugins/trouble.lua:8-13`

### 场景 C：修改代码后整理结果

1. 保存时自动格式化
2. `InsertLeave` / 保存 / 进入 buffer 时自动 lint
3. 需要时手动用 `SPC mp` 格式化，`SPC l` 重新 lint

对应代码：
- `lua/josean/plugins/formatting.lua:24-37`
- `lua/josean/plugins/linting.lua:16-27`

### 场景 D：处理 Git 变更

1. 用 `]h` / `[h` 在 hunk 间跳转
2. 用 `SPC hs` 或 `SPC hr` 处理当前 hunk
3. 用 `SPC hp` 预览变更
4. 用 `SPC hb` 看 blame

对应代码：`lua/josean/plugins/gitsigns.lua:12-44`

---

## 22. 快捷键速查表

### 基础

- `jk`：退出插入模式
- `<leader>nh`：清除搜索高亮
- `<leader>+`：数字加一
- `<leader>-`：数字减一

对应代码：`lua/josean/core/keymaps.lua:5-11`

### 分屏 / 标签页

- `<leader>sv` / `<leader>sh` / `<leader>se` / `<leader>sx`
- `<leader>sm`
- `<leader>to` / `<leader>tx` / `<leader>tn` / `<leader>tp` / `<leader>tf`

对应代码：
- `lua/josean/core/keymaps.lua:13-23`
- `lua/josean/plugins/vim-maximizer.lua:1-6`

### 文件与搜索

- `-`
- `<leader>ee` / `<leader>ef`
- `<leader>ff` / `<leader>fr` / `<leader>fs` / `<leader>fc` / `<leader>ft`
- `<leader>h`

对应代码：
- `lua/josean/plugins/oil.lua:191-195`
- `lua/josean/plugins/telescope.lua:41-48`
- `lua/josean/plugins/hop.lua:7-11`

### 会话与终端

- `<leader>wr` / `<leader>ws`
- `<C-\\>`
- 终端中 `<Esc>`

对应代码：
- `lua/josean/plugins/auto-session.lua:11-14`
- `lua/josean/plugins/toggleterm.lua:7-14`

### LSP / 诊断

- `gR` / `gD` / `gd` / `gi` / `gt`
- `<leader>ca` / `<leader>rn`
- `<leader>D` / `<leader>d` / `[d` / `]d`
- `K`
- `<leader>rs`

对应代码：`lua/josean/plugins/lsp/lspconfig.lua:22-60`

### 格式化 / Lint

- `<leader>mp`
- `<leader>l`

对应代码：
- `lua/josean/plugins/formatting.lua:31-37`
- `lua/josean/plugins/linting.lua:25-27`

### TODO / Trouble

- `]t` / `[t`
- `<leader>xw` / `<leader>xd` / `<leader>xq` / `<leader>xl` / `<leader>xt`

对应代码：
- `lua/josean/plugins/todo-comments.lua:11-17`
- `lua/josean/plugins/trouble.lua:8-13`

### Git

- `]h` / `[h`
- `<leader>hs` / `<leader>hr` / `<leader>hS` / `<leader>hR`
- `<leader>hu` / `<leader>hp`
- `<leader>hb` / `<leader>hB`
- `<leader>hd` / `<leader>hD`
- `ih`

对应代码：`lua/josean/plugins/gitsigns.lua:12-44`

### 翻译

- `mm` / `mk`

对应代码：
- `lua/josean/plugins/trans.lua:6-13`

---

## 23. 相关配置与研究文件

如果你之后想继续对照源码理解这套配置，可以优先看这些文件：

- 研究文档：`research/codebase-state-2026-03-19.md:1-99`
- 入口：`init.lua:1-2`
- 启动与插件导入：`lua/josean/lazy.lua:1-22`
- 基础键位：`lua/josean/core/keymaps.lua:1-24`
- 基础选项：`lua/josean/core/options.lua:1-39`
- LSP：`lua/josean/plugins/lsp/lspconfig.lua:1-128`
- 搜索：`lua/josean/plugins/telescope.lua:1-50`
- 文件浏览：`lua/josean/plugins/oil.lua:1-197`

这份手册对应的是当前仓库状态下的配置行为。