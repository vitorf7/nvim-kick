return {
  -- Use the local plugin directory
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/bitbucket.nvim',
  event = 'VeryLazy',
  name = 'bitbucket.nvim',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  keys = {
    -- Quick access to Bitbucket menu
    { '<leader>bb', '<cmd>Bitbucket<cr>', desc = 'Bitbucket menu' },
    -- PR management
    { '<leader>bp', '<cmd>Bitbucket pr list<cr>', desc = 'List PRs' },
    { '<leader>bv', '<cmd>Bitbucket pr view<cr>', desc = 'View PR' },
    -- Review workflow
    { '<leader>br', '<cmd>Bitbucket review start<cr>', desc = 'Start PR review' },
    -- Issues
    { '<leader>bi', '<cmd>Bitbucket issue list<cr>', desc = 'List issues' },
    -- Auth
    { '<leader>ba', '<cmd>Bitbucket auth status<cr>', desc = 'Auth status' },
  },

  opts = {
    -- Use snacks.nvim picker
    picker = 'snacks',
    -- Prefer CLI when available, fallback to REST API
    prefer_cli = true,
    cli_cmd = 'bkt',
    -- Enable all features
    enable_reviews = true,
    enable_issues = true,
    enable_pipelines = false,
    -- Use local filesystem for diffs
    use_local_fs = true,
  },

  config = function(_, opts) require('bitbucket').setup(opts) end,
}
