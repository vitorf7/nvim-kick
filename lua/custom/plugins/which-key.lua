return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    preset = 'modern',
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    win = {
      wo = {
        winblend = 0,
      },
    },
    spec = {
      { '<leader>C', group = '[C]ode (language specific)', mode = { 'n', 'v' } },
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]est' },
      { '<leader>T', group = '[T]oggle' },
      { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
      { '<leader>x', group = 'Trouble/[X] diagnostics' },
      { '<leader>h', group = '[H]arpoon' },
      -- AI assistants
      { '<leader>A', group = '[A]I Assistants', mode = { 'n', 'v' } },
      { '<leader>O', group = '[O]pencode', mode = { 'n', 'v' } },
      -- GitHub (Octo)
      { '<leader>o', group = '[O]cto (GitHub)' },
      -- LSP and Code
      { '<leader>l', group = '[L]SP/Code' },
      -- UI
      { '<leader>u', group = '[U]I' },
      -- Overseer (Task runner)
      { '<leader>R', group = '[R]unner/Task', icon = '󰑮' },
      -- Markdown
      { '<leader>m', group = '[M]arkdown' },
    },
  },
}
