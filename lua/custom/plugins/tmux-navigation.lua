return {
  'alexghergh/nvim-tmux-navigation',
  keys = {
    { '<C-h>', function() require('nvim-tmux-navigation').NvimTmuxNavigateLeft() end, desc = 'Navigate Left (tmux)' },
    { '<C-j>', function() require('nvim-tmux-navigation').NvimTmuxNavigateDown() end, desc = 'Navigate Down (tmux)' },
    { '<C-k>', function() require('nvim-tmux-navigation').NvimTmuxNavigateUp() end, desc = 'Navigate Up (tmux)' },
    { '<C-l>', function() require('nvim-tmux-navigation').NvimTmuxNavigateRight() end, desc = 'Navigate Right (tmux)' },
    { '<C-\\>', function() require('nvim-tmux-navigation').NvimTmuxNavigateLastActive() end, desc = 'Navigate Last Active (tmux)' },
    { '<C-Space>', function() require('nvim-tmux-navigation').NvimTmuxNavigateNext() end, desc = 'Navigate Next (tmux)' },
  },
}
