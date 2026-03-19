return {
  {
    dir = '~/.config/nvim/lua/custom',
    name = 'worktree_plugin',
    dependencies = {
      'folke/snacks.nvim',
    },
    config = function()
      local worktree = require 'custom.worktree_plugin'
      worktree.setup {
        keymaps = {
          ['<leader>gwm'] = 'manage',
          ['<leader>gws'] = 'switch',
          ['<leader>gwc'] = 'create_worktree',
          ['<leader>gwl'] = 'list',
        },
      }
    end,
    keys = {
      { '<leader>gwm', desc = 'Git Worktree: Manage' },
      { '<leader>gws', desc = 'Git Worktree: Switch' },
      { '<leader>gwc', desc = 'Git Worktree: Create' },
      { '<leader>gwl', desc = 'Git Worktree: List' },
    },
  },
}
