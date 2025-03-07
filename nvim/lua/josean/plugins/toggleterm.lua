return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = { --[[ things you want to change go here]]
  },
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      -- 打开新终端后自动进入插入模式
      start_in_insert = true,
      -- 在当前buffer的下方打开新终端
      direction = "float",
    })
    vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
  end,
}
