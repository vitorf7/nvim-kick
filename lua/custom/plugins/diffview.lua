return {
  'dlyongemallo/diffview-plus.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  dependencies = { 'rickhowe/diffchar.vim' },
  opts = {
    enhanced_diff_hl = true,
    diffopt = { algorithm = 'histogram' },
    use_icons = true,
    view = {
      default = { layout = 'diff2_horizontal' },
      merge_tool = { layout = 'diff3_horizontal' },
    },
    file_panel = {
      listing_style = 'tree',
      win_config = { position = 'left', width = 35 }, -- Use "auto" to fit content
    },
  },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [D]iffview' },
    { '<leader>gD', '<cmd>DiffviewClose<cr>', desc = '[G]it [D]iffview Close' },
    { '<leader>gf', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it [F]ile History' },
    { '<leader>gF', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it All [F]ile History' },
  },
}
