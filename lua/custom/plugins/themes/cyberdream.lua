local M = {
  'scottmckendry/cyberdream.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('cyberdream').setup {
      transparent = true,
      italic_comments = true,
      hide_fillchars = false,
      borderless_telescope = true,
    }

    vim.cmd.colorscheme 'cyberdream' -- set the colorscheme
  end,
}

return M
