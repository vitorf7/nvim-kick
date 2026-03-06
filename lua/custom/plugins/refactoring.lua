return {
  'ThePrimeagen/refactoring.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    prompt_func_return_type = {
      go = true,
    },
  },
  keys = {
    {
      '<leader>lR',
      function()
        require('refactoring').select_refactor {}
      end,
      desc = 'Refactoring',
      mode = { 'n', 'x' },
    },
  },
  config = function(_, opts)
    require('refactoring').setup(opts)
  end,
}
