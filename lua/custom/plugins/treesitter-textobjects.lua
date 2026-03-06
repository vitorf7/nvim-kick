return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  lazy = true,
  branch = 'main',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  opts = {
    select = {
      enable = true,
      lookahead = true,
    },
    move = {
      enable = true,
      set_jumps = true,
    },
    swap = {
      enable = true,
    },
  },
  config = function()
    -- Movement keymaps
    vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
    end, { desc = 'Go to next start function' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
    end, { desc = 'Go to next start class' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, ']a', function()
      require('nvim-treesitter-textobjects.move').goto_next_start('@parameter.inner', 'textobjects')
    end, { desc = 'Go to next start parameter' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, ']F', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
    end, { desc = 'Go to next end function' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, ']C', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
    end, { desc = 'Go to next end class' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, ']A', function()
      require('nvim-treesitter-textobjects.move').goto_next_end('@parameter.inner', 'textobjects')
    end, { desc = 'Go to next end parameter' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
    end, { desc = 'Go to previous start function' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
    end, { desc = 'Go to previous start class' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[a', function()
      require('nvim-treesitter-textobjects.move').goto_previous_start('@parameter.inner', 'textobjects')
    end, { desc = 'Go to previous start parameter' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[F', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
    end, { desc = 'Go to previous end function' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[C', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
    end, { desc = 'Go to previous end class' })
    
    vim.keymap.set({ 'n', 'x', 'o' }, '[A', function()
      require('nvim-treesitter-textobjects.move').goto_previous_end('@parameter.inner', 'textobjects')
    end, { desc = 'Go to previous end parameter' })
    
    -- Selection keymaps
    vim.keymap.set({ 'x', 'o' }, 'af', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
    end, { desc = 'Around function' })
    
    vim.keymap.set({ 'x', 'o' }, 'if', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
    end, { desc = 'Inside function' })
    
    vim.keymap.set({ 'x', 'o' }, 'ac', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
    end, { desc = 'Around class' })
    
    vim.keymap.set({ 'x', 'o' }, 'ic', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
    end, { desc = 'Inside class' })
    
    vim.keymap.set({ 'x', 'o' }, 'aa', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@parameter.outer', 'textobjects')
    end, { desc = 'Around parameter' })
    
    vim.keymap.set({ 'x', 'o' }, 'ia', function()
      require('nvim-treesitter-textobjects.select').select_textobject('@parameter.inner', 'textobjects')
    end, { desc = 'Inside parameter' })
  end,
}
