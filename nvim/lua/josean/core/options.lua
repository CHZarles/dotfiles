vim.cmd("let g:netrw_liststyle = 3")

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

local nvim_python_host = vim.fn.expand("~/.venvs/nvim/bin/python3")
if vim.fn.executable(nvim_python_host) == 1 then
  vim.g.python3_host_prog = nvim_python_host
elseif vim.fn.executable("python3") == 1 then
  vim.g.python3_host_prog = vim.fn.exepath("python3")
end

local nvim_python_bin = vim.fn.expand("~/.venvs/nvim/bin")
if vim.fn.isdirectory(nvim_python_bin) == 1 then
  local path_sep = package.config:sub(1, 1) == "\\" and ";" or ":"
  local current_path = vim.env.PATH or ""

  if not vim.startswith(current_path, nvim_python_bin .. path_sep) and current_path ~= nvim_python_bin then
    vim.env.PATH = nvim_python_bin .. path_sep .. current_path
  end
end

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- sessions
opt.sessionoptions:append("localoptions")

-- turn off swapfile
opt.swapfile = false
