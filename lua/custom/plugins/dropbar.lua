return {
  'Bekaboo/dropbar.nvim',
  event = 'BufReadPost',
  opts = {
    bar = {
      enable = function(buf, win)
        -- Disable dropbar in mini.files buffers and non-file buffers
        local ft = vim.bo[buf].filetype
        local bt = vim.bo[buf].buftype
        if ft == 'minifiles' or bt ~= '' then
          return false
        end
        return true
      end,
      padding = { left = 1, right = 1 },
      separator = ' > ',
      extend = true,
    },
    menu = {
      win_configs = {
        border = 'rounded',
      },
    },
  },
  keys = {
    { '<leader>cp', function() require('dropbar.api').pick() end, desc = '[C]ode [P]ick symbols in winbar' },
  },
}
