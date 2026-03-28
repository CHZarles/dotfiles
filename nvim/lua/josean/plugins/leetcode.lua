return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    cn = {
      enabled = true,
      translator = true,
      translate_problems = true,
    },
    lang = "python3",
    picker = {
      provider = "telescope",
    },
    plugins = {
      non_standalone = true,
    },
  },
}
