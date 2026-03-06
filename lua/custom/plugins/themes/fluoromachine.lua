local M = {
  'maxmx03/fluoromachine.nvim',
  config = function()
    local fm = require 'fluoromachine'

    fm.setup {
      glow = false,
      transparent = 'full',
      theme = 'fluoromachine',
    }

    vim.cmd.colorscheme 'fluoromachine'
  end,
}

return M
