return {
  'stevearc/overseer.nvim',
  cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerOpen', 'OverseerClose' },
  keys = {
    { '<leader>Rr', '<cmd>OverseerRun<cr>', desc = '[R]unner [R]un task' },
    { '<leader>Rt', '<cmd>OverseerToggle<cr>', desc = '[R]unner [T]oggle' },
    { '<leader>Ro', '<cmd>OverseerOpen<cr>', desc = '[R]unner [O]pen' },
    { '<leader>Rc', '<cmd>OverseerClose<cr>', desc = '[R]unner [C]lose' },
  },
  opts = {
    task_list = {
      direction = 'bottom',
      min_height = 25,
      max_height = 25,
      default_detail = 1,
    },
  },
}
