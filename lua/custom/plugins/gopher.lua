return {
  'olexsmir/gopher.nvim',
  ft = 'go',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'mfussenegger/nvim-dap', -- (optional) only if you use `gopher.dap`
  },
  opts = {
    commands = {
      go = 'go',
      gomodifytags = 'gomodifytags',
      gotests = 'gotests',
      impl = 'impl',
      iferr = 'iferr',
      dlv = 'dlv',
    },
    gotests = {
      -- gotests doesn't have template named "default" so this plugin uses "default" to set the default template
      template = 'default',
      -- path to a directory containing custom test code templates
      template_dir = nil,
      -- switch table tests from using slice to map (with test name for the key)
      -- works only with gotests installed from develop branch
      named = false,
    },
    gotag = {
      transform = 'snakecase',
    },
  },
  config = function(_, opts) require('gopher').setup(opts) end,
  keys = {
    { '<leader>Csj', '<cmd>GoTagAdd json<cr>', desc = 'Add json struct tags', ft = 'go' },
    { '<leader>Csy', '<cmd>GoTagAdd yaml<cr>', desc = 'Add yaml struct tags', ft = 'go' },
    { '<leader>Cse', '<cmd>GoTagAdd db<cr>', desc = 'Add db struct tags', ft = 'go' },
    { '<leader>Csr', '<cmd>GoTagRm<cr>', desc = 'Remove struct tags', ft = 'go' },
    { '<leader>Cie', '<cmd>GoIfErr<cr>', desc = 'Go Add if err', ft = 'go' },
    { '<leader>Cim', '<cmd>GoImpl<cr>', desc = 'Go Implement interface', ft = 'go' },
    { '<leader>Ct', '<cmd>GoTestsAdd<cr>', desc = 'Go Add test for function', ft = 'go' },
    { '<leader>Cta', '<cmd>GoTestsAll<cr>', desc = 'Go Add tests for all functions', ft = 'go' },
    { '<leader>Cte', '<cmd>GoTestsExp<cr>', desc = 'Go Add exported tests', ft = 'go' },
  },
}
