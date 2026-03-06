return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  event = 'VeryLazy',
  config = function()
    local ok, harpoon = pcall(require, 'harpoon')
    if not ok then
      vim.notify('Failed to load harpoon', vim.log.levels.ERROR)
      return
    end

    -- Basic setup without custom settings
    harpoon:setup()

    -- Keymaps
    vim.keymap.set('n', '<leader>ha', function()
      local list = harpoon:list()
      if list then
        list:add()
        vim.notify('Added to harpoon', vim.log.levels.INFO)
      end
    end, { desc = '[H]arpoon [A]dd file' })

    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon Quick Menu' })

    -- Navigation keys (changed to avoid conflict with tmux navigation)
    vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
    vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
    vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
    vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })
  end,
}
