# Codebase research: current state on 2026-03-19

## High-level summary

This repository is a Neovim configuration with a single entrypoint in `init.lua`, which loads core editor settings first and then bootstraps plugin loading through Lazy.nvim. The source tree is centered on `lua/josean/core` for base options and keymaps, `lua/josean/plugins` for general plugin specifications, and `lua/josean/plugins/lsp` for LSP and related tooling. The root also contains a plugin lockfile, a Stylua configuration file, a persisted Vim session file, and a Tree-sitter query override under `after/queries`. The plugin set currently covers explorer/navigation, search, editing helpers, UI surfaces, Git, sessions, Treesitter, translation tooling, completion, LSP, formatting, and linting.

## Detailed findings by area

### 1. Repository layout and entrypoints

- The root contains `init.lua`, `lua/`, `after/`, `lazy-lock.json`, `.stylua.toml`, and `Session.vim`; there are no other source directories at the top level. `init.lua` is the runtime entrypoint for the configuration. `init.lua:1-2`
- `init.lua` loads `josean.core` before `josean.lazy`, which establishes editor defaults before plugin bootstrap begins. `init.lua:1-2`
- Lazy.nvim bootstrap lives in `lua/josean/lazy.lua`. It computes the Lazy.nvim install path, clones the repository if missing, prepends it to `runtimepath`, and calls `require("lazy").setup()` with two imports: `josean.plugins` and `josean.plugins.lsp`. `lua/josean/lazy.lua:1-22`
- The top-level plugin import file returns a single base dependency entry for `nvim-lua/plenary.nvim`. `lua/josean/plugins/init.lua:1-4`
- The plugin lockfile records pinned branches and commits for the currently resolved plugin set. `lazy-lock.json:1-58`
- The repository includes a Stylua configuration that sets spaces with width 2. `.stylua.toml:1-2`
- The `after` tree contains a Tree-sitter textobject query extension for ECMAScript property captures. `after/queries/ecma/textobjects.scm:1-5`
- The persisted session file changes into `~/.config/nvim`, adds and opens `lua/josean/plugins/alpha.lua`, restores window and fold state, and fires `SessionLoadPost`. `Session.vim:1-53`

### 2. Core editor configuration

- `lua/josean/core/init.lua` is a two-line module that loads `options.lua` and `keymaps.lua`. `lua/josean/core/init.lua:1-2`
- `options.lua` sets `netrw_liststyle = 3`, enables line numbers with relative numbering, configures two-space indentation with `expandtab`, disables wrapping, enables smart search behavior, turns on `cursorline`, sets `termguicolors` and `background = "dark"`, keeps the signcolumn visible, extends backspace behavior, appends `unnamedplus` to the clipboard, opens vertical splits to the right and horizontal splits below, and disables swapfiles. `lua/josean/core/options.lua:1-39`
- `keymaps.lua` sets the mapleader to a space, maps `jk` in insert mode to `<ESC>`, clears search highlighting with `<leader>nh`, maps `<leader>+` and `<leader>-` to increment and decrement numbers, adds split-management mappings under `<leader>s*`, and adds tab-management mappings under `<leader>t*`. `lua/josean/core/keymaps.lua:1-24`

### 3. Plugin bootstrap organization

- General plugin specs are stored as individual files under `lua/josean/plugins/*.lua`, while LSP-related specs are stored under `lua/josean/plugins/lsp/*.lua`; both groups are imported by Lazy.nvim from `lua/josean/lazy.lua`. `lua/josean/lazy.lua:14-22`
- The current general plugin files are `alpha.lua`, `auto-session.lua`, `autopairs.lua`, `bufferline.lua`, `colorscheme.lua`, `comment.lua`, `distant.lua`, `dressing.lua`, `formatting.lua`, `gitsigns.lua`, `hop.lua`, `indent-blankline.lua`, `linting.lua`, `lualine.lua`, `markdown-render.lua`, `max-windows.lua`, `neogit.lua`, `nvim-cmp.lua`, `nvim-tree.lua`, `nvim-treesitter-text-objects.lua`, `oil.lua`, `substitute.lua`, `surround.lua`, `telescope.lua`, `todo-comments.lua`, `toggleterm.lua`, `trans.lua`, `treesitter.lua`, `trouble.lua`, `vim-maximizer.lua`, and `which-key.lua`; this plugin tree is imported through Lazy.nvim from `lua/josean/lazy.lua`. `lua/josean/lazy.lua:14-22`
- The current LSP plugin files are `lspconfig.lua` and `mason.lua`, imported through the same Lazy.nvim setup. `lua/josean/lazy.lua:14-22`

### 4. Navigation, explorer, and workspace surfaces

- `telescope.lua` configures Telescope on branch `0.1.x`, adds `plenary.nvim`, `telescope-fzf-native.nvim`, `nvim-web-devicons`, and `todo-comments.nvim` as dependencies, loads the `fzf` extension, configures insert-mode Telescope mappings, and binds `<leader>ff`, `<leader>fr`, `<leader>fs`, `<leader>fc`, and `<leader>ft` for file search, oldfiles, live grep, string grep, and todo search. `lua/josean/plugins/telescope.lua:1-50`
- `oil.lua` configures `stevearc/oil.nvim` as the default file explorer with directory-buffer takeover enabled. The file defines Oil buffer keymaps, preview/progress/SSH behavior, view settings, and repo-level mappings `-`, `<leader>ee`, and `<leader>ef`. `lua/josean/plugins/oil.lua:1-198`
- `nvim-tree.lua` defines an alternate explorer setup gated by `enabled = vim.fn.has("nvim-0.12") == 0`. It configures view width, relative numbering, renderer icons, file filters, Git handling, and maps `<leader>ee`, `<leader>ef`, `<leader>ec`, and `<leader>er`. `lua/josean/plugins/nvim-tree.lua:1-57`
- `hop.lua` configures `smoka7/hop.nvim`, sets a custom key sequence, and maps `<leader>h` to `HopWord`. `lua/josean/plugins/hop.lua:1-15`
- `auto-session.lua` configures `rmagatti/auto-session` with auto-restore disabled and suppression rules for selected directories, and it maps `<leader>wr` to `SessionRestore` and `<leader>ws` to `SessionSave`. `lua/josean/plugins/auto-session.lua:1-16`
- `toggleterm.lua` configures floating terminals with `open_mapping = [[<c-\>]]`, `start_in_insert = true`, and a terminal-mode `<Esc>` mapping that exits to normal mode. `lua/josean/plugins/toggleterm.lua:1-16`
- `vim-maximizer.lua` maps `<leader>sm` to `MaximizerToggle`. `lua/josean/plugins/vim-maximizer.lua:1-7`
- `max-windows.lua` loads `anuvyklack/windows.nvim` with `middleclass` as a dependency. `lua/josean/plugins/max-windows.lua:1-9`
- `which-key.lua` sets `timeoutlen = 500` and loads `which-key.nvim` on `VeryLazy`. `lua/josean/plugins/which-key.lua:1-13`

### 5. UI, status, and dashboard components

- `colorscheme.lua` contains the active theme configuration. The enabled plugin entry is `ellisonleao/gruvbox.nvim` with `priority = 1000`; the file sets Grubox options and runs `vim.cmd("colorscheme gruvbox")`. The same file also contains commented theme configuration blocks that are not active. `lua/josean/plugins/colorscheme.lua:1-132`
- `alpha.lua` configures the Alpha dashboard on `VimEnter`, defines an ASCII header, and registers buttons for new file, file search, word search, session restore, and quit. It also disables folding for the Alpha buffer. `lua/josean/plugins/alpha.lua:1-50`
- `lualine.lua` configures `nvim-lualine/lualine.nvim` with `nvim-web-devicons`, defines color tables and a theme table, and includes Lazy.nvim update status in the `lualine_x` section. `lua/josean/plugins/lualine.lua:1-73`
- `bufferline.lua` configures `akinsho/bufferline.nvim` with `options.mode = "tabs"`. `lua/josean/plugins/bufferline.lua:1-10`
- `indent-blankline.lua` configures indent guides with `indent.char = "┊"`. `lua/josean/plugins/indent-blankline.lua:1-9`
- `dressing.lua` loads `stevearc/dressing.nvim` on `VeryLazy` with no extra options in the file. `lua/josean/plugins/dressing.lua:1-5`
- `todo-comments.lua` configures keyword groups, signs, highlight patterns, search behavior, and the `]t` and `[t` keymaps for todo navigation. `lua/josean/plugins/todo-comments.lua:1-84`
- `trouble.lua` configures `folke/trouble.nvim` with `focus = true`, depends on `todo-comments.nvim`, registers the `Trouble` command, and maps `<leader>xx`, `<leader>xw`, `<leader>xd`, `<leader>xq`, `<leader>xl`, and `<leader>xt`. `lua/josean/plugins/trouble.lua:1-16`
- `markdown-render.lua` loads `markview.nvim` as an in-editor previewer, keeps it eagerly loaded (`lazy = false`), and maps `<leader>mt` to `:Markview toggle` plus `<leader>ms` to `:Markview disable`. Markdown math rendering depends on the `latex` Tree-sitter parser declared in `treesitter.lua`. `lua/josean/plugins/markdown-render.lua:1-8` `lua/josean/plugins/treesitter.lua:24-47`

### 6. Editing helpers, text objects, and syntax-aware behavior

- `surround.lua` loads `kylechui/nvim-surround` on buffer read/new-file events with `config = true` and a tagged version. `lua/josean/plugins/surround.lua:1-16`
- `substitute.lua` loads `gbprod/substitute.nvim` on buffer events, calls `setup()`, and maps `s`, `ss`, `S`, and visual `s` for substitution actions. `lua/josean/plugins/substitute.lua:1-17`
- `comment.lua` loads `numToStr/Comment.nvim`, depends on `nvim-ts-context-commentstring`, and installs `ts_context_commentstring` as the `pre_hook`. `lua/josean/plugins/comment.lua:1-19`
- `autopairs.lua` loads on `InsertEnter`, configures `windwp/nvim-autopairs` with Tree-sitter checks, and attaches completion-confirm integration through `cmp.event:on("confirm_done", ...)`. `lua/josean/plugins/autopairs.lua:1-31`
- `treesitter.lua` loads `nvim-treesitter` on buffer events, builds with `:TSUpdate`, depends on `nvim-ts-autotag`, enables highlighting, indentation, autotagging, and incremental selection, and declares parser installs for JSON, JavaScript, TypeScript, TSX, YAML, HTML, CSS, Prisma, Markdown, Markdown inline, Svelte, GraphQL, Bash, Lua, Vim, Dockerfile, Gitignore, query, Vimdoc, C, and Python. `lua/josean/plugins/treesitter.lua:1-58`
- `nvim-treesitter-text-objects.lua` configures selection, movement, swap, and repeatable textobject mappings for assignments, properties, parameters, conditionals, loops, calls, functions, and classes. `lua/josean/plugins/nvim-treesitter-text-objects.lua:1-112`
- The ECMAScript query extension under `after/queries/ecma/textobjects.scm` adds property captures for object pairs (`@property.lhs`, `@property.inner`, `@property.rhs`, `@property.outer`). `after/queries/ecma/textobjects.scm:1-5`

### 7. Git, remote interaction, and related tooling

- `gitsigns.lua` loads on buffer events and creates buffer-local mappings for hunk navigation, staging, resetting, preview, blame, diffing, and the `ih` text object. `lua/josean/plugins/gitsigns.lua:1-47`
- `neogit.lua` loads `NeogitOrg/neogit` with `plenary.nvim` and optional `diffview.nvim` and `telescope.nvim` dependencies, using `config = true`. `lua/josean/plugins/neogit.lua:1-13`
- `distant.lua` loads `chipsenkbeil/distant.nvim` from branch `v0.3` and runs `require("distant"):setup()`. `lua/josean/plugins/distant.lua:1-7`

### 8. Language-adjacent plugins

- `trans.lua` loads `JuanZoran/Trans.nvim`, builds through `require("Trans").install()`, depends on `sqlite.lua`, and maps `mm` and `mk` in normal and visual modes. `lua/josean/plugins/trans.lua:1-17`

### 9. LSP, completion, formatting, and linting

- `mason.lua` configures `mason.nvim` and its companion plugins `mason-lspconfig.nvim` and `mason-tool-installer.nvim`. It defines UI icons, ensures the LSP servers `lua_ls` and `pyright` are installed, and ensures the tools `prettier`, `stylua`, `isort`, and `black` are installed. `lua/josean/plugins/lsp/mason.lua:1-53`
- `lspconfig.lua` loads `neovim/nvim-lspconfig` on buffer read/new-file events, depends on `cmp-nvim-lsp`, `nvim-lsp-file-operations`, and `neodev.nvim`, creates `LspAttach` mappings for references, definitions, declarations, implementations, type definitions, code actions, rename, diagnostics, hover, restart, and symbol search, defines diagnostic signs, and sets up server configurations for `pyright`, `svelte`, `graphql`, `emmet_ls`, and `lua_ls`. `lua/josean/plugins/lsp/lspconfig.lua:1-128`
- The `pyright` configuration sets `pythonPath = "python3"`. `lua/josean/plugins/lsp/lspconfig.lua:87-94`
- The `svelte` configuration registers a `BufWritePost` autocmd for `*.js` and `*.ts` files that notifies the Svelte server with `$/onDidChangeTsOrJsFile`. `lua/josean/plugins/lsp/lspconfig.lua:96-105`
- The `lua_ls` configuration marks `vim` as a recognized global and sets completion call snippets to `Replace`. `lua/josean/plugins/lsp/lspconfig.lua:114-126`
- `nvim-cmp.lua` loads on `InsertEnter`, depends on buffer/path/LSP/snippet/icon sources, loads VS Code snippets lazily, configures completion windows and insert-mode mappings, expands snippets through LuaSnip, and registers completion sources `nvim_lsp`, `luasnip`, `buffer`, and `path`. `lua/josean/plugins/nvim-cmp.lua:1-67`
- `formatting.lua` configures `stevearc/conform.nvim` to format JavaScript, TypeScript, React variants, Svelte, CSS, HTML, JSON, YAML, Markdown, GraphQL, Liquid, Lua, and Python files with formatter mappings to Prettier, Stylua, Isort, and Black. It enables format-on-save and maps `<leader>mp` in normal and visual mode for manual formatting. `lua/josean/plugins/formatting.lua:1-39`
- `linting.lua` configures `mfussenegger/nvim-lint`, maps JavaScript, TypeScript, React variants, and Svelte to `eslint_d`, maps Python to `pylint`, installs an autocmd group on `BufEnter`, `BufWritePost`, and `InsertLeave`, and maps `<leader>l` for manual linting. `lua/josean/plugins/linting.lua:1-29`

## Cross-component connections and data flow

- Boot flow is linear from `init.lua` into core configuration and then into Lazy.nvim bootstrap: `init.lua` -> `lua/josean/core/init.lua` -> `lua/josean/core/options.lua` and `lua/josean/core/keymaps.lua` -> `lua/josean/lazy.lua` -> imported plugin spec trees. `init.lua:1-2`, `lua/josean/core/init.lua:1-2`, `lua/josean/lazy.lua:1-22`
- Completion and LSP are connected through `cmp_nvim_lsp.default_capabilities()`, which is merged into server setup in `lspconfig.lua`; `nvim-cmp.lua` defines the completion sources consumed at insert time, and `autopairs.lua` listens to `nvim-cmp` confirmation events. `lua/josean/plugins/lsp/lspconfig.lua:64-85`, `lua/josean/plugins/nvim-cmp.lua:1-67`, `lua/josean/plugins/autopairs.lua:1-31`
- External tool management is split across Mason, Conform, and nvim-lint: Mason installs `lua_ls`, `pyright`, `prettier`, `stylua`, `isort`, and `black`; Conform maps formatter execution per filetype; nvim-lint maps linter execution per filetype. `lua/josean/plugins/lsp/mason.lua:1-53`, `lua/josean/plugins/formatting.lua:1-39`, `lua/josean/plugins/linting.lua:1-29`
- Explorer behavior is version-gated between two implementations. `oil.nvim` is configured as the default explorer, while `nvim-tree.lua` is only enabled when Neovim 0.12 is not present; both files define overlapping explorer mappings. `lua/josean/plugins/oil.lua:1-198`, `lua/josean/plugins/nvim-tree.lua:1-57`
- Session and dashboard behavior are connected through Alpha and auto-session: the dashboard exposes a restore-session action, while auto-session defines the `SessionRestore` and `SessionSave` commands and mappings. `lua/josean/plugins/alpha.lua:1-50`, `lua/josean/plugins/auto-session.lua:1-16`
- Search and diagnostics surfaces are linked in two places: Telescope includes a todo-comments picker, and Trouble depends on todo-comments and exposes a todo view. `lua/josean/plugins/telescope.lua:1-50`, `lua/josean/plugins/todo-comments.lua:1-84`, `lua/josean/plugins/trouble.lua:1-16`
- Tree-sitter textobject behavior is defined by both plugin configuration and a query override: `nvim-treesitter-text-objects.lua` defines the mappings, and `after/queries/ecma/textobjects.scm` extends the underlying ECMAScript property captures those mappings can use. `lua/josean/plugins/nvim-treesitter-text-objects.lua:1-112`, `after/queries/ecma/textobjects.scm:1-5`
