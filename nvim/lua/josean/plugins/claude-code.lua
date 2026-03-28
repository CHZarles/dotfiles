return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeContinue",
    "ClaudeCodeResume",
    "ClaudeCodeVerbose",
    "ClaudeCodeVersion",
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Claude Code" },
    { "<leader>ac", [[<C-\><C-n><cmd>ClaudeCode<CR>]], mode = "t", desc = "Claude Code" },
    { "<leader>aC", "<cmd>ClaudeCodeContinue<CR>", desc = "Claude Code continue" },
    { "<leader>aR", "<cmd>ClaudeCodeResume<CR>", desc = "Claude Code resume" },
    { "<leader>aV", "<cmd>ClaudeCodeVerbose<CR>", desc = "Claude Code verbose" },
  },
  opts = {
    window = {
      position = "botright",
      split_ratio = 0.35,
      enter_insert = true,
      hide_numbers = true,
      hide_signcolumn = true,
      float = {
        width = "92%",
        height = "88%",
        row = "center",
        col = "center",
        relative = "editor",
        border = "rounded",
      },
    },
    refresh = {
      enable = true,
      updatetime = 100,
      timer_interval = 1000,
      show_notifications = false,
    },
    git = {
      use_git_root = true,
      multi_instance = true,
    },
    command = "claude",
    keymaps = {
      toggle = {
        normal = false,
        terminal = false,
        variants = {
          continue = false,
          verbose = false,
        },
      },
      window_navigation = true,
      scrolling = true,
    },
  },
  config = function(_, opts)
    require("claude-code").setup(opts)
  end,
}
