return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  config = function()
    require("markview").setup({
      preview = {
        enable = false,
        enable_hybrid_mode = false,
        condition = function(buffer)
          if not vim.list_contains({ "markdown", "quarto", "rmd", "typst", "asciidoc" }, vim.bo[buffer].filetype) then
            return nil
          end

          local ok, parser = pcall(vim.treesitter.get_parser, buffer)
          return ok and parser ~= nil or false
        end,
      },
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
