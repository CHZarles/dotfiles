return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  config = function()
    require("josean.markview_cases").patch()

    require("markview").setup({
      preview = {
        enable = true,
        enable_hybrid_mode = false,
        max_buf_lines = 5000,
      },
    })

    local group = vim.api.nvim_create_augroup("josean_markview_attach", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "markdown", "quarto", "rmd", "typst", "asciidoc" },
      callback = function(args)
        if not vim.api.nvim_buf_is_valid(args.buf) then
          return
        end

        local commands = require("markview.commands")
        local state = require("markview.state")

        if not state.buf_attached(args.buf) then
          commands.attach(args.buf)
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>mt",
      function()
        local buffer = vim.api.nvim_get_current_buf()
        local commands = require("markview.commands")
        local state = require("markview.state")

        if not state.buf_attached(buffer) then
          commands.attach(buffer)
        end

        commands.toggle(buffer)
      end,
      desc = "Toggle markdown preview",
    },
    {
      "<leader>ms",
      function()
        local buffer = vim.api.nvim_get_current_buf()
        local commands = require("markview.commands")
        local state = require("markview.state")

        if state.buf_attached(buffer) then
          commands.disable(buffer)
        end
      end,
      desc = "Disable markdown preview",
    },
  },
}
