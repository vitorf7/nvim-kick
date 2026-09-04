-- return {
--   'ThePrimeagen/refactoring.nvim',
--   lazy = false,
--   -- dependencies = {
--   --   'nvim-lua/plenary.nvim',
--   --   'nvim-treesitter/nvim-treesitter',
--   -- },
--   opts = {
--     -- prompt_func_return_type = {
--     --   go = true,
--     -- },
--   },
--   keys = {
--     {
--       '<leader>lR',
--       function() require('refactoring').select_refactor() end,
--       desc = 'Refactoring',
--       mode = { 'n', 'x' },
--     },
--   },
--   config = function(_, opts) require('refactoring').setup(opts) end,
-- }
return {
  { 'lewis6991/async.nvim', lazy = true },

  {
    'ThePrimeagen/refactoring.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
      { '<leader>r', '', desc = '+refactor', mode = { 'n', 'x' } },
      {
        '<leader>rs',
        function() return require('refactoring').select_refactor() end,
        mode = { 'n', 'x' },
        desc = 'Select Refactor',
      },
      {
        '<leader>ri',
        function() return require('refactoring').inline_var() end,
        mode = { 'n', 'x' },
        desc = 'Inline Variable',
        expr = true,
      },
      {
        '<leader>rP',
        function() return require('refactoring.debug').print_loc { output_location = 'below' } end,
        desc = 'Debug Print Location',
        expr = true,
      },
      {
        '<leader>rp',
        function() return require('refactoring.debug').print_var { output_location = 'below' } .. 'iw' end,
        mode = { 'n', 'x' },
        desc = 'Debug Print Variable',
        expr = true,
      },
      {
        '<leader>rc',
        function() return require('refactoring.debug').cleanup { restore_view = true } .. 'ag' end,
        desc = 'Debug Cleanup',
        expr = true,
      },
      {
        '<leader>rf',
        function() return require('refactoring').extract_func() end,
        mode = { 'n', 'x' },
        desc = 'Extract Function',
        expr = true,
      },
      {
        '<leader>rF',
        function() return require('refactoring').extract_func_to_file() end,
        mode = { 'n', 'x' },
        desc = 'Extract Function To File',
        expr = true,
      },
      {
        '<leader>rx',
        function() return require('refactoring').extract_var() end,
        mode = { 'n', 'x' },
        desc = 'Extract Variable',
        expr = true,
      },
    },
    opts = {},
  },
}
