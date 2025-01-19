return {
  "smoka7/hop.nvim",
  version = "*",
  opts = {
    keys = "etovxqpdygfblzhckisuran",
  },
  config = function()
    -- place this in one of your configuration file(s)
    require("hop").setup({})
    vim.g.mapleader = " "
    vim.keymap.set("n", "<leader>h", "<Cmd>HopWord<CR>")
    -- vim.keymap.set('n', '<leader>F', '<Cmd>HopWordCurrentLine<CR>')
    -- vim.keymap.set('n', '<leader>l', '<Cmd>HopLine<CR>')
  end,
}
