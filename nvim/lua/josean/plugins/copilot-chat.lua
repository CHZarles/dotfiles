return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "main",
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
  },

  config = function()
    require("CopilotChat").setup({})
    vim.keymap.set("n", "<leader>cc", "<CMD>CopilotChat<CR>", { desc = "Open CopilotChat" })
    vim.keymap.set("v", "<leader>2", "<CMD>CopilotChatOptimize<CR>", { desc = "Open CopilotChat" })
    vim.keymap.set("v", "<leader>3", "<CMD>CopilotChatDocs<CR>", { desc = "Open CopilotChat" })
    vim.keymap.set("v", "<leader>4", "<CMD>CopilotChatExplain<CR>", { desc = "Open CopilotChat" })
  end,
}
