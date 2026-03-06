return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [D]iffview' },
    { '<leader>gD', '<cmd>DiffviewClose<cr>', desc = '[G]it [D]iffview Close' },
    { '<leader>gf', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it [F]ile History' },
    { '<leader>gF', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it All [F]ile History' },
  },
}
