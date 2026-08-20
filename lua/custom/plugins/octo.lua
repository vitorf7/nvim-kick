return {
  enabled = false,
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = { 'Octo' },
  opts = {
    use_local_fs = true,
    enable_builtin = true,
    mappings = {
      review_diff = {
        select_next_entry = { lhs = '<Tab>', desc = 'move to previous changed file' },
        select_prev_entry = { lhs = '<S-Tab>', desc = 'move to next changed file' },
      },
    },
  },
  config = function(_, opts)
    require('octo').setup(opts)

    vim.treesitter.language.register('markdown', 'octo')
    vim.keymap.set('i', '@', '@<C-x><C-o>', { silent = true, buffer = true })
    vim.keymap.set('i', '#', '#<C-x><C-o>', { silent = true, buffer = true })
  end,
  keys = {
    { '<leader>o', '<cmd>Octo<cr>', desc = 'Octo' },
  },
}
