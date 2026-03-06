return {
  'folke/sidekick.nvim',
  lazy = true,
  enabled = true,
  opts = {
    cli = {
      mux = {
        backend = 'tmux',
        enabled = true,
        create = 'split',
        split = {
          vertical = true,
          size = 0.4,
        },
      },
    },
  },
  keys = {
    {
      '<leader>A.',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick Toggle',
      mode = { 'n', 't', 'i', 'x' },
    },
    {
      '<leader>Aa',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick Toggle CLI',
    },
    {
      '<leader>As',
      function()
        require('sidekick.cli').select()
      end,
      desc = 'Select CLI',
    },
    {
      '<leader>Ad',
      function()
        require('sidekick.cli').close()
      end,
      desc = 'Detach a CLI Session',
    },
    {
      '<leader>At',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      mode = { 'x', 'n' },
      desc = 'Send This',
    },
    {
      '<leader>Af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'Send File',
    },
    {
      '<leader>Av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      mode = { 'x' },
      desc = 'Send Visual Selection',
    },
    {
      '<leader>Ap',
      function()
        require('sidekick.cli').prompt()
      end,
      mode = { 'n', 'x' },
      desc = 'Sidekick Select Prompt',
    },
    {
      '<leader>Ac',
      function()
        require('sidekick.cli').toggle { name = 'claude', focus = true }
      end,
      desc = 'Sidekick Toggle Claude',
    },
    {
      '<leader>AC',
      function()
        require('sidekick.cli').toggle { name = 'cursor', focus = true }
      end,
      desc = 'Sidekick Toggle Cursor',
    },
    {
      '<leader>AO',
      function()
        require('sidekick.cli').toggle { name = 'opencode', focus = true }
      end,
      desc = 'Sidekick Toggle OpenCode',
    },
  },
}
