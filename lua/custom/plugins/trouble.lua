return {
  'folke/trouble.nvim',
  cmd = { 'Trouble' },
  opts = {
    auto_close = false,
    auto_preview = true,
    auto_refresh = true,
    focus = false,
    follow = true,
    indent_guides = true,
    keys = {
      ['<cr>'] = 'jump_close',
      ['<esc>'] = 'close',
    },
    modes = {
      lsp_document_diagnostics = {
        mode = 'lsp_document_diagnostics',
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_refresh = true,
        focus = false,
        follow = true,
        indent_guides = true,
        win = { position = 'bottom' },
      },
    },
  },
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
    { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols (Trouble)' },
    { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP Definitions / references / ... (Trouble)' },
    { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List (Trouble)' },
    { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List (Trouble)' },
  },
}
