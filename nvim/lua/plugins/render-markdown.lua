-- ~/.config/nvim/lua/plugins/render-markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "codecompanion", "Avante" },
    opts = {
      completions = { lsp = { enabled = true } },
      heading = {
        sign = false,          -- не засорять signcolumn
        position = "inline",   -- ### остаётся на месте, не сдвигает текст
        width = "block",
        left_pad = 0,
        right_pad = 2,
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 2,
        language_pad = 2,
      },
      bullet = { icons = { "●", "○", "◆", "◇" } },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      pipe_table = { preset = "round" },
    },
  },
  -- парсеры обязательны, иначе рендер не заведётся
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(
        opts.ensure_installed,
        { "markdown", "markdown_inline", "html", "latex" }
      )
    end,
  },
}
