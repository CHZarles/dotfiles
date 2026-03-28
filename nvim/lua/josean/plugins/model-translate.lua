return {
  "gsuuon/model.nvim",
  cmd = {
    "M",
    "Model",
    "Mchat",
    "Mcancel",
    "Mdelete",
    "Mselect",
    "Mshow",
    "ModelTranslate",
    "ModelTranslateBuffer",
  },
  ft = "mchat",
  init = function()
    vim.filetype.add({
      extension = {
        mchat = "mchat",
      },
    })
  end,
  keys = {
    {
      "<leader>tt",
      ":ModelTranslate<CR>",
      mode = "v",
      desc = "Translate selection to Chinese",
    },
    {
      "<leader>tT",
      "<Cmd>ModelTranslateBuffer<CR>",
      desc = "Translate buffer to Chinese",
    },
  },
  opts = {
    prompts = {},
    chats = {},
  },
  config = function(_, opts)
    require("model").setup(opts)
    require("josean.model_translate").setup()
  end,
}
