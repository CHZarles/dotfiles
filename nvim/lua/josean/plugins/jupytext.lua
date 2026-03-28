return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,
  opts = {
    style = "markdown",
    output_extension = "md",
    force_ft = "markdown",
  },
  config = function(_, opts)
    require("jupytext").setup(opts)
  end,
}
