return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  init = function()
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_echo_preview_url = 1
    vim.g.mkdp_filetypes = { "markdown" }

    vim.cmd([[
      function! OpenMarkdownPreview(url) abort
        call jobstart([
              \ 'powershell.exe',
              \ '-NoProfile',
              \ '-Command',
              \ 'Start-Process',
              \ a:url,
              \ ], {'detach': v:true})
      endfunction
    ]])

    vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
  end,
  keys = {
    {
      "<leader>mp",
      "<cmd>MarkdownPreviewToggle<CR>",
      desc = "Toggle browser markdown preview",
    },
    {
      "<leader>mP",
      "<cmd>MarkdownPreviewStop<CR>",
      desc = "Stop browser markdown preview",
    },
  },
}
