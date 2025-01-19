return {
  -- "catppuccin/nvim",
  -- name = "catppuccin",
  -- priority = 1000,
  -- config = function()
  --   require("catppuccin").setup({
  --     flavour = "mocha", -- latte, frappe, macchiato, mocha
  --     background = { -- :h background
  --       light = "latte",
  --       dark = "mocha",
  --     },
  --     transparent_background = false, -- disables setting the background color.
  --     show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
  --     term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
  --     dim_inactive = {
  --       enabled = false, -- dims the background color of inactive window
  --       shade = "dark",
  --       percentage = 0.15, -- percentage of the shade to apply to the inactive window
  --     },
  --     no_italic = false, -- Force no italic
  --     no_bold = false, -- Force no bold
  --     no_underline = false, -- Force no underline
  --     styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
  --       comments = { "italic" }, -- Change the style of comments
  --       conditionals = { "italic" },
  --       loops = {},
  --       functions = {},
  --       keywords = {},
  --       strings = {},
  --       variables = {},
  --       numbers = {},
  --       booleans = {},
  --       properties = {},
  --       types = {},
  --       operators = {},
  --       -- miscs = {}, -- Uncomment to turn off hard-coded styles
  --     },
  --     color_overrides = {},
  --     custom_highlights = {},
  --     default_integrations = true,
  --     integrations = {
  --       cmp = true,
  --       gitsigns = true,
  --       nvimtree = true,
  --       treesitter = true,
  --       notify = false,
  --       mini = {
  --         enabled = true,
  --         indentscope_color = "",
  --       },
  --       -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
  --     },
  --   })
  --
  --   -- setup must be called before loading
  --   vim.cmd.colorscheme("catppuccin")
  -- end,

  -- "folke/tokyonight.nvim",
  -- priority = 1000,
  -- config = function()
  --   local transparent = false -- set to true if you would like to enable transparency
  --
  --   local bg = "#011628"
  --   local bg_dark = "#011423"
  --   local bg_highlight = "#143652"
  --   local bg_search = "#0A64AC"
  --   local bg_visual = "#275378"
  --   local fg = "#CBE0F0"
  --   local fg_dark = "#B4D0E9"
  --   local fg_gutter = "#627E97"
  --   local border = "#547998"
  --
  --   require("tokyonight").setup({
  --     style = "night",
  --     transparent = transparent,
  --     styles = {
  --       sidebars = transparent and "transparent" or "dark",
  --       floats = transparent and "transparent" or "dark",
  --     },
  --     on_colors = function(colors)
  --       colors.bg = bg
  --       colors.bg_dark = transparent and colors.none or bg_dark
  --       colors.bg_float = transparent and colors.none or bg_dark
  --       colors.bg_highlight = bg_highlight
  --       colors.bg_popup = bg_dark
  --       colors.bg_search = bg_search
  --       colors.bg_sidebar = transparent and colors.none or bg_dark
  --       colors.bg_statusline = transparent and colors.none or bg_dark
  --       colors.bg_visual = bg_visual
  --       colors.border = border
  --       colors.fg = fg
  --       colors.fg_dark = fg_dark
  --       colors.fg_float = fg
  --       colors.fg_gutter = fg_gutter
  --       colors.fg_sidebar = fg_dark
  --     end,
  --   })
  --
  --   vim.cmd("colorscheme tokyonight")
  -- end,

  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true, -- invert background for search, diffs, statuslines and errors
      contrast = "", -- can be "hard", "soft" or empty string
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
    })
    vim.cmd("colorscheme gruvbox")
  end,
}
