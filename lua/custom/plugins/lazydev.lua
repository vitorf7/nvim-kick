return {
  'folke/lazydev.nvim',
  ft = 'lua', -- only load on lua files
  opts = {
    library = {
      -- Load luvit types when the `vim.uv` word is found
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      -- Neovim runtime types (essential for vim global)
      { path = vim.env.VIMRUNTIME .. '/lua/vim', words = { 'vim' } },
      { path = vim.env.VIMRUNTIME .. '/lua', words = { 'vim' } },
      -- lazy.nvim and plugin types
      'lazy.nvim',
      { 'nvim-dap-ui' },
      { path = '${3rd}/busted/library', words = { 'describe' } },
      { path = '${3rd}/luassert/library', words = { 'assert' } },
      -- LazyVim types
      'LazyVim',
      { path = 'snacks.nvim', words = { 'Snacks' } },
      { path = 'LazyVim', words = { 'LazyVim' } },
    },
  },
}
