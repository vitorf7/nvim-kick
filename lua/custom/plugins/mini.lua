return {
  'echasnovski/mini.nvim',
  version = '*',
  event = { 'BufReadPost', 'VeryLazy' },
  config = function()
    -- Mini.ai - better text objects
    require('mini.ai').setup { n_lines = 500 }

    -- Mini.surround - surround manipulation
    require('mini.surround').setup()

    -- Mini.statusline
    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    statusline.section_location = function() return '%2l:%-2v' end

    -- Mini.pairs - auto pairs
    require('mini.pairs').setup()

    -- Mini.comment - comments
    require('mini.comment').setup()
  end,
  keys = {},
}
